#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build results
clang++ -std=c++17 -O2 -Wall -Wextra -Wpedantic src/main.cpp src/transform.cpp -o build/lab1
if [ "$#" -eq 0 ]; then
    ./build/lab1
    printf '\nPress Return to close...'
    read -r unused
else
    ./build/lab1 "$@"
fi
