#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
clang++ -std=c++17 -O2 -Wall -Wextra -Wpedantic src/main.cpp src/lab2_mac.S -o build/lab2
./build/lab2 "$@"
