#!/usr/bin/env python3
"""Exact Fraction branch + expression oracle; binary inputs use float.hex()."""
from collections import Counter
from fractions import Fraction
import math
import random
import subprocess
import sys

rng = random.Random(6004)
tiny = math.ulp(0.0)
pairs = []
for boundary in (-5.0, 9.0):
    # Include both sides, exact equality, subnormal operands and both orders.
    for delta in (0.0, tiny, -tiny, 2**-53, -(2**-53), 2**-52, -(2**-52)):
        pairs.extend([(boundary, delta), (delta, boundary)])
    xs = [-999.0, -100.0, -9.0, -5.0, -1.0, 0.0, 1.0, 5.0, 9.0, 100.0, 999.0]
    xs += [rng.uniform(-980, 980) for _ in range(1200)]
    for x in xs:
        y = boundary - x
        for direction in (-math.inf, None, math.inf):
            yy = y if direction is None else math.nextafter(y, direction)
            if abs(yy) <= 1000:
                pairs.extend([(x, yy), (yy, x)])

payload = ''.join(f'{x.hex()} {y.hex()}\n' for x, y in pairs)
proc = subprocess.run([sys.argv[1]], input=payload, text=True, capture_output=True, check=True)
lines = proc.stdout.splitlines()
assert len(lines) == len(pairs), (len(lines), len(pairs), proc.stderr)
counts = Counter()
for (x, y), line in zip(pairs, lines):
    a, b = Fraction.from_float(x), Fraction.from_float(y)
    total = a + b
    if total > 9:
        kind, exact = 'high', 5*a + 2*a*b + 1
    elif total < -5:
        kind, exact = 'low', (2*a*b + 3)/(b*b + 4)
    else:
        kind, exact = 'middle', 3*a*a - 2*b*b + 1
    counts[kind] += 1
    if total in (Fraction(9), Fraction(-5)):
        counts['exact boundary'] += 1
    if float(total) in (9.0, -5.0) and total not in (Fraction(9), Fraction(-5)):
        counts['rounded boundary, not equal'] += 1
    expected = float(exact)
    got = float.fromhex(line)
    if not math.isfinite(got) or abs(got - expected) > 3e-12 * max(1.0, abs(expected)):
        raise AssertionError(f'{x.hex()} {y.hex()} branch={kind} got={got} expected={expected}, exact_sum={total}')
assert all(counts[k] for k in ('high', 'middle', 'low', 'exact boundary', 'rounded boundary, not equal')), counts
print(f'PASS Fraction {len(pairs)} cases; {dict(counts)}')
