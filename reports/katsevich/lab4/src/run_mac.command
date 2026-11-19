#!/bin/bash
# Build and test the x86-64 binaries; run interactively unless --test is given.
set -euo pipefail
cd "$(dirname "$0")"
if [[ "${1:-}" != "" && "${1:-}" != "--test" ]] || [[ $# -gt 1 ]]; then
    printf 'Usage: %s [--test]\n' "$0" >&2
    exit 2
fi
if [[ "$(uname -s)" != Darwin ]]; then
    printf 'error: macOS is required\n' >&2
    exit 1
fi
mkdir -p build
flags=(-arch x86_64 -std=c++17 -O2 -Wall -Wextra -Werror)
clang++ "${flags[@]}" main.cpp variant6.S -o build/lab4
clang++ "${flags[@]}" tests.cpp variant6.S -o build/tests
clang++ "${flags[@]}" test_exact_sum.cpp variant6.S -o build/test_exact_sum
clang++ "${flags[@]}" test_fraction_bridge.cpp variant6.S -o build/test_fraction_bridge
arch -x86_64 build/tests
arch -x86_64 build/test_exact_sum
python3 test_fraction.py "$PWD/build/test_fraction_bridge"
python3 test_cli.py "$PWD/build/lab4"
python3 test_subnormal_cli.py "$PWD/build/lab4"
if [[ "${1:-}" != "--test" ]]; then
    exec arch -x86_64 build/lab4
fi
