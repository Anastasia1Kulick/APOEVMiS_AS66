// main.cpp
// Проверка корректности асм-вставки и сравнение быстродействия с C++.
#include <windows.h>
#include <cstdio>
#include <cstring>
#include <chrono>

extern "C" void ReverseStringAsm(char* str);   // реализация в lab1_asm.asm
void ReverseStringCpp(char* str);              // реализация в lab1_cpp.cpp

int main()
{
    SetConsoleOutputCP(CP_UTF8);
    const char* sample = "Laboratornaya rabota nomer odin - assemblernaya vstavka";

    // 1. Проверка корректности: оба варианта должны дать одинаковый результат
    char buf1[256];
    char buf2[256];
    strcpy_s(buf1, sample);
    strcpy_s(buf2, sample);

    ReverseStringAsm(buf1);
    ReverseStringCpp(buf2);

    printf("Исходная строка : %s\n", sample);
    printf("Результат ASM   : %s\n", buf1);
    printf("Результат C++   : %s\n", buf2);
    printf("Совпадают       : %s\n\n", (strcmp(buf1, buf2) == 0) ? "да" : "НЕТ (ошибка!)");

    // 2. Замер быстродействия
    const int ITERATIONS = 2000000;
    char work[256];

    auto t1 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < ITERATIONS; ++i)
    {
        strcpy_s(work, sample);
        ReverseStringAsm(work);
    }
    auto t2 = std::chrono::high_resolution_clock::now();

    for (int i = 0; i < ITERATIONS; ++i)
    {
        strcpy_s(work, sample);
        ReverseStringCpp(work);
    }
    auto t3 = std::chrono::high_resolution_clock::now();

    double asmMs = std::chrono::duration<double, std::milli>(t2 - t1).count();
    double cppMs = std::chrono::duration<double, std::milli>(t3 - t2).count();

    printf("ASM: %.2f ms  (%d итераций)\n", asmMs, ITERATIONS);
    printf("C++: %.2f ms  (%d итераций)\n", cppMs, ITERATIONS);

    return 0;
}