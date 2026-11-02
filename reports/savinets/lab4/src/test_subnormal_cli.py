#!/usr/bin/env python3
"""Independent end-to-end regression: input parsing, not branch selection."""
import subprocess
import sys

app = sys.argv[1]
failed = []
for token in ('5e-324', '1e-320', '1e-309', '-5e-324', '-1e-320', '-1e-309', '0e-9999'):
    data = f'real\n{token}\n0\n'
    p = subprocess.run([app], input=data, text=True, capture_output=True)
    if p.returncode != 0 or 'result = ' not in p.stdout:
        failed.append((token, p.returncode, p.stderr.strip()))
for token in ('1e-9999', '-1e-9999'):
    p = subprocess.run([app], input=f'real\n{token}\n0\n', text=True, capture_output=True)
    if p.returncode == 0 or 'error:' not in p.stderr:
        failed.append((token, p.returncode, p.stdout.strip()))
for item in failed:
    print('FAIL', item, file=sys.stderr)
if failed:
    sys.exit(1)
print('PASS subnormal CLI 7 accepted + 2 underflow rejected')
