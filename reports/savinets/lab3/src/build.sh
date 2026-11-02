#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
    printf '%s\n' 'Ошибка: требуется macOS на Apple Silicon (arm64).' >&2
    exit 1
fi
mkdir -p build
flags=(-std=c++17 -Wall -Wextra -Wpedantic -O2)
clang++ "${flags[@]}" main.cpp remove_spaces.S -o build/lab3
clang++ "${flags[@]}" tests.cpp remove_spaces.S -o build/tests
printf '%s\n' 'Сборка завершена: build/lab3, build/tests'
./build/tests
python3 test_cli.py ./build/lab3
