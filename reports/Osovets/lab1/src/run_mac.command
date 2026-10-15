#!/bin/bash
set -e
cd "$(dirname "$0")"
mkdir -p build
FLAGS="-std=c++17 -O2 -Wall -Wextra lab1.cpp -o build/lab1"
if ! clang++ $FLAGS 2>/dev/null; then
    SDK=$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX26*.sdk 2>/dev/null | head -1)
    clang++ $FLAGS ${SDK:+-isysroot "$SDK"}
fi
./build/lab1 "$@"
