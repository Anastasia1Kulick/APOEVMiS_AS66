#!/usr/bin/env python3
"""Black-box tests for both interactive modes and invalid input."""
import math
import subprocess
import sys

app = sys.argv[1]
cases = [
    ('integer\n-6\n0\n', .75), ('real\n-6\n0\n', .75),
    ('integer\n10\n0\n', 51), ('real\n10\n0\n', 51),
    ('integer\n-5\n0\n', 76), ('real\n-5\n0\n', 76),
    ('integer\n9\n0\n', 244), ('real\n9\n0\n', 244),
    ('integer\n-3\n-3\n', 21/13), ('real\n-3\n-3\n', 21/13),
    ('real\n5.5\n4.25\n', 75.25), ('real\n-1.25\n2.75\n', -9.4375),
    ('integer\n  +1000  \n-1000\n', 1000001),
    ('real\n  0.0e-9999  \n0\n', 1), ('real\n9\n5e-324\n', 46),
    ('real\n-5\n-5e-324\n', .75),
]
for data, expected in cases:
    p = subprocess.run([app], input=data, text=True, capture_output=True)
    if p.returncode != 0 or 'result = ' not in p.stdout:
        raise AssertionError((data, p.returncode, p.stdout, p.stderr))
    got = float(p.stdout.split('result = ')[-1].strip())
    if not math.isclose(got, expected, rel_tol=1e-12, abs_tol=1e-12):
        raise AssertionError((data, got, expected))
invalid = [
    '', 'bad\n1\n2\n', 'integer\n1.5\n2\n', 'integer\nabc\n2\n',
    'integer\n1001\n0\n', 'integer\n-1001\n0\n', 'integer\n1\n',
    'integer\n1 2\n0\n', 'real\nnan\n0\n', 'real\ninf\n0\n',
    'real\n1e309\n0\n', 'real\n0\n1000.1\n', 'real\n1.0x\n0\n',
    'real\n1e-9999\n0\n', 'real\n-1e-9999\n0\n', 'real\n1 2\n0\n',
    'real\nNaN\n0\n', 'real\n-infinity\n0\n', 'real\n1\x00x\n0\n',
    'integer\n2147483648\n0\n', 'integer\n1e0\n0\n'
]
for data in invalid:
    p = subprocess.run([app], input=data, text=True, capture_output=True)
    if p.returncode == 0 or 'error:' not in p.stderr:
        raise AssertionError((data, p.returncode, p.stdout, p.stderr))
print(f'PASS {len(cases)} CLI values + {len(invalid)} invalid inputs')
