#!/usr/bin/env python3
"""Проверяет реальный ввод/вывод готовой программы без оболочки."""
import subprocess
import sys

exe = sys.argv[1] if len(sys.argv) > 1 else "./build/lab3"
prompt = "Введите строку: ".encode()
prefix = "Результат: ".encode()
cases = [
    ("empty", b"\n", b""),
    ("spaces only", b"     \n", b""),
    ("no spaces", b"abc\n", b"abc"),
    ("repeated and edge spaces", b"  a  b  \n", b"ab"),
    ("UTF-8 Russian", "  Привет  мир!  \n".encode(), "Приветмир!".encode()),
    ("tabs and nonbreaking space", " a\tb\u00a0c \n".encode(), "a\tb\u00a0c".encode()),
    ("long line", b" a" * 4096 + b"\n", b"a" * 4096),
    ("unterminated input line", b" a b ", b"ab"),
    ("embedded NUL", b"a\x00 b\n", b"a\x00b"),
]
for name, input_bytes, expected in cases:
    result = subprocess.run([exe], input=input_bytes, capture_output=True, check=False)
    actual = prompt + prefix + expected + b"\n"
    if result.returncode != 0 or result.stderr or result.stdout != actual:
        print(f"FAIL CLI: {name}: exit={result.returncode}, stdout={result.stdout!r}, stderr={result.stderr!r}")
        sys.exit(1)
    print(f"PASS CLI: {name}")
result = subprocess.run([exe], input=b"", capture_output=True, check=False)
if result.returncode != 0 or result.stdout != prompt or result.stderr:
    print(f"FAIL CLI: EOF: {result!r}")
    sys.exit(1)
print("PASS CLI: EOF")
print(f"CLI: {len(cases) + 1} cases passed")
