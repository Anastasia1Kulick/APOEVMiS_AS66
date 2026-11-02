#!/bin/bash
set -e
cd "$(dirname "$0")"
mkdir -p build
PART="${1:-1}"
FLAGS="-arch x86_64 -x assembler lab4_part$PART.asm -o build/lab4_part$PART"
if ! clang $FLAGS 2>/dev/null; then
    SDK=$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX26*.sdk 2>/dev/null | head -1)
    clang $FLAGS ${SDK:+-isysroot "$SDK"}
fi
arch -x86_64 ./build/lab4_part$PART
