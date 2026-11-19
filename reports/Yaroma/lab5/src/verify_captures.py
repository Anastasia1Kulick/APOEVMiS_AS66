"""Recalculate the submitted captures without starting a capture or changing the network."""
import csv
from decimal import Decimal
import hashlib
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parent
TSHARK=shutil.which('tshark') or 'D:/WiresharkPortable/App/Wireshark/tshark.exe'
FIELDS=['frame.number','frame.time_epoch','frame.len','frame.cap_len',
        'ip.src','ip.dst','ip.proto','tcp.srcport','tcp.dstport','tcp.flags',
        'icmp.type','arp.opcode','tls.handshake.extensions_server_name']

def require(ok, message):
    if not ok: raise RuntimeError(message)

def main():
    expected=json.loads((ROOT/'measurements.json').read_text(encoding='utf-8'))
    for line in (ROOT/'SHA256SUMS.txt').read_text(encoding='ascii').splitlines():
        digest,name=line.split('  ',1)
        require(hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,'SHA256 mismatch: '+name)
    for name,known in expected.items():
        args=[TSHARK,'-r',str(ROOT/name),'-T','fields','-E','separator=/t','-E','quote=d','-E','occurrence=f']
        for field in FIELDS: args+=['-e',field]
        p=subprocess.run(args,capture_output=True,encoding='utf-8',check=True)
        rows=[dict(zip(FIELDS,r)) for r in csv.reader(io.StringIO(p.stdout),delimiter='\t')]
        require(len(rows)==known['packets'], 'Packet count mismatch: '+name)
        sizes=[int(r['frame.len']) for r in rows]
        require(all(r['frame.len']==r['frame.cap_len'] for r in rows),'Truncated packets')
        require(sum(sizes)==known['bytes'], 'Byte count mismatch: '+name)
        duration=max(Decimal(r['frame.time_epoch']) for r in rows)-min(Decimal(r['frame.time_epoch']) for r in rows)
        require(abs(duration-Decimal(str(known['duration'])))<Decimal('0.000001'),'Duration mismatch')
        if name in ('huawei.pcapng','filter_https.pcapng','filter_syn.pcapng'):
            require(all(r['ip.proto']=='6' and '72.247.69.67' in (r['ip.src'],r['ip.dst'])
                    and '443' in (r['tcp.srcport'],r['tcp.dstport']) for r in rows),'HTTPS filter mismatch')
        if name=='huawei.pcapng':
            require(any(r['tls.handshake.extensions_server_name']=='www.huawei.com' for r in rows),'Huawei SNI missing')
            require([int(r['tcp.flags'],16)&0x12 for r in rows[:3]]==[2,18,16],'TCP handshake mismatch')
        elif name=='filter_syn.pcapng':
            require(all(int(r['tcp.flags'],16)&2 for r in rows),'SYN filter mismatch')
        elif name=='ping_self.pcapng':
            require(all(r['ip.src']==r['ip.dst']=='100.70.47.58' for r in rows),'Local ping address mismatch')
            require([r['icmp.type'] for r in rows]==['8','0']*4,'Local echo pairs mismatch')
        elif name=='filter_icmp.pcapng':
            require(all(r['ip.proto']=='1' and set((r['ip.src'],r['ip.dst']))=={'100.70.47.58','100.70.0.1'} for r in rows),'Gateway ICMP filter mismatch')
            require([r['icmp.type'] for r in rows]==['8','0']*4,'Gateway echo pairs mismatch')
        elif name=='arp_gateway.pcapng':
            require([r['arp.opcode'] for r in rows]==['1','2'],'ARP request/reply mismatch')
        print(f'{name}: {len(rows)} packets, {sum(sizes)} bytes, {duration} s; verified')
    print('PASS: 6 capture files; SHA256, complete packets, statistics, and protocol/filter checks.')

if __name__=='__main__':
    try: main()
    except (OSError,RuntimeError,subprocess.CalledProcessError) as exc:
        print(str(exc),file=sys.stderr)
        sys.exit(1)
