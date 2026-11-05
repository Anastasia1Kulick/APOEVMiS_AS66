from pathlib import Path
from fractions import Fraction
import json, math, random, re, subprocess
ROOT=Path(__file__).resolve().parents[1]/'src/build/Win32'
def oracle(x,y):
    # Exact rational arithmetic, independently evaluated from input binary values.
    x,y=Fraction(x),Fraction(y)
    if x-y>2: return 1,float((x*x-4*y+5)/(x*x+2))
    if x-y<-4: return 2,float((2*x+y)/(3*x*x+4))
    return 3,float(x*x-2*y+3)
def run(exe,data,valid=None):
    p=subprocess.run([str(exe)],input=data,capture_output=True,timeout=10)
    text=p.stdout.decode('utf-8').replace('\r\n','\n')
    if valid is None:
        assert p.returncode==1 and 'Ошибка:' in text and 'Результат:' not in text,(data,text)
    else:
        mode,x,y=valid
        b,want=oracle(x,y)
        m=re.search(r'Результат: ([^\n]+)',text)
        assert p.returncode==0 and m and f'Ветвь {b}:' in text,(data,text,b,want)
        got=float(m[1]); assert math.isfinite(got) and math.isclose(got,want,rel_tol=3e-15,abs_tol=1e-300),(data,text,want)
    return text
fixtures=[(1,3,0),(1,0,5),(1,2,0),(1,0,4),(1,0,0),
    (1,2147483647,-2147483648),(1,-2147483648,2147483647),
    (1,2147483647,2147483647),(1,-2147483648,-2147483648),
    (2,2.5,.25),(2,.25,5),(2,.5,1.25),(2,0.,4.),(2,2.,0.),
    (2,1e308,0.),(2,0.,1e308),(2,1e-308,0.),(2,5e-324,0.)]
for b in [-4.,2.]:
    for x in [b,math.nextafter(b,-math.inf),math.nextafter(b,math.inf)]: fixtures.append((2,x,0.))
rng=random.Random(412)
for mode in [1,2]:
    for _ in range(140):
        x,y=[rng.randint(-2147483648,2147483647) for _ in range(2)] if mode==1 else [rng.uniform(-1e100,1e100) for _ in range(2)]
        fixtures.append((mode,x,y))
    for y in [-100,0,100]:
        for d in [-5,-4,-3,1,2,3]: fixtures.append((mode,y+d,y))
invalid=[b'',b'\n',b'0\n',b'3\n',b'1.0\n',b'bad\n',b'1\n',
 b'1\n\n0\n',b'1\n1.5\n0\n',b'1\n2147483648\n0\n',b'1\n-2147483649\n0\n',
 b'1\n0\n2147483648\n',b'1\n1x\n0\n',b'1\n0x10\n0\n',b'1\n3\x00bad\n0\n',
 b'1\n1\r2\n0\n',b'2\nNaN\n0\n',b'2\ninf\n0\n',b'2\n-inf\n0\n',
 b'2\n0\nnan\n',b'2\n1e309\n0\n',b'2\n1e-9999\n0\n',b'2\n1,2\n0\n',
 b'2\n1e\n0\n',b'2\n1.25junk\n0\n',b'2\n1e308\n1e308\n',
 b'1\n'+b'0'*256+b'\n0\n']
logs=[]
for config in ['Release','Debug']:
    exe=ROOT/config/'Lab4Variant12.exe'
    for item in fixtures:
        mode,x,y=item
        data=f'{mode}\n{x}\n{y}\n'.encode()
        text=run(exe,data,item)
        if config=='Release' and item in fixtures[:5]+fixtures[9:14]: logs.append({'input':data.decode(),'output':text})
    for data in invalid: run(exe,data)
    run(exe,b' 1 \r\n +3 \t\r\n -0 \t\r\n',(1,3,0))
    run(exe,b'2\n2.5\n.25',(2,2.5,.25))
    print(f'{config}: {len(fixtures)+len(invalid)+2} CLI checks passed',flush=True)
