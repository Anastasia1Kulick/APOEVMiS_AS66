#!/bin/bash
# Сборка и запуск лабораторной работы №2 на Mac (Apple Silicon, ARM64).
#   bash run_mac.sh          - ввод своего текста
#   bash run_mac.sh --test   - автоматическая проверка
set -e
cd "$(dirname "$0")"
mkdir -p build
clang++ -std=c++17 -O2 -Wall -Wextra -Wpedantic -c lab2.cpp -o build/lab2.o
clang++ -c text_proc.S -o build/text_proc.o
clang++ build/lab2.o build/text_proc.o -liconv -o build/lab2
./build/lab2 "$@"
