#!/bin/bash
# Сборка и запуск лабораторной работы №1 на Mac.
#   bash run_mac.sh            - ввод своей строки + сравнение скорости
#   bash run_mac.sh --demo     - строка HelloWorld без ввода
#   bash run_mac.sh --test     - автоматическая проверка C++ и ассемблера
# Уровень оптимизации можно сменить: OPT=-O0 bash run_mac.sh --demo
set -e
cd "$(dirname "$0")"
mkdir -p build
clang++ -std=c++17 ${OPT:--O2} -Wall -Wextra -Wpedantic lab1.cpp -o build/lab1
./build/lab1 "$@"
