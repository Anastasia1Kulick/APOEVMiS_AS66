#!/bin/bash
set -e
cd "$(dirname "$0")"
mkdir -p build
FLAGS="-arch x86_64 -x assembler lab2.asm -o build/lab2"
if ! clang $FLAGS 2>/dev/null; then
    SDK=$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX26*.sdk 2>/dev/null | head -1)
    clang $FLAGS ${SDK:+-isysroot "$SDK"}
fi
arch -x86_64 ./build/lab2
