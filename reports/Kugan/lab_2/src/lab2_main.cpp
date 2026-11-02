// lab2_main.cpp
// Лабораторная работа №2, вариант 9. Куган Н. Л., АС-66. Платформа: x86.
// Ввод текста, проверка условия, преобразование, вывод.
//
// Строки для проверки (вводить в консоль вместе с точкой):
//   ПРИВЕТ мир 5x ABC.     -> условие TRUE,  результат: РПЧЭЪН мир 5x ABC
//   Привет 7z, ЁЖ АЯБ.     -> условие TRUE,  результат: Рривет 7z, ЁЩ ЯАЮ
//   a1b2c.                 -> условие TRUE,  текст не меняется
//   ПРИВЕТ МИР.            -> условие TRUE (цифр нет), результат: РПЧЭЪН УЧП
//   abc 9.                 -> условие FALSE (цифра последняя)
//   12a.                   -> условие FALSE (за цифрой 1 идёт цифра 2)
//   .                      -> ошибка: пустой ввод
//   ТЕКСТ БЕЗ ТОЧКИ        -> ошибка: нет точки (Enter до точки)

#include <cstdio>
#include <windows.h>

#ifndef _M_IX86
#error Assembly module is built with ml.exe (x86 only): choose platform "x86" (Win32).
#endif

extern "C" int  CheckConditionAsm(const char* text, int len);   // реализация в lab2_asm.asm
extern "C" void TransformTextAsm(char* text, int len);          // реализация в lab2_asm.asm

const int MAX_LEN = 100;

int ReadText(char* buf, int& len)
{
    len = 0;
    for (;;)
    {
        int c = std::getchar();
        if (c == '.')
            break;
        if (c == '\n' || c == EOF)
            return 2;
        if (len >= MAX_LEN)
            return 2;
        buf[len++] = (char)c;
    }
    return (len == 0) ? 1 : 0;
}

int main()
{
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    char text[MAX_LEN + 1] = { 0 };
    int len = 0;

    std::printf("========================================================\n");
    std::printf(" Lab 2, variant 9. Character data processing\n");
    std::printf(" Condition: every digit is followed by a lowercase\n");
    std::printf("            latin letter (a..z).\n");
    std::printf(" Rule     : every uppercase RUSSIAN letter is replaced\n");
    std::printf("            by its symmetric one (A<->YA, B<->YU, ...).\n");
    std::printf("========================================================\n\n");
    std::printf("Enter text (max 100 chars, end with '.'):\n> ");

    int status = ReadText(text, len);
    if (status == 1)
    {
        std::printf("\nError: empty input, this is not a text!\n");
        return 0;
    }
    if (status == 2)
    {
        std::printf("\nError: no '.' within 100 characters, this is not a text!\n");
        return 0;
    }
    std::printf("\nOriginal text   : %.*s\n", len, text);

    if (CheckConditionAsm(text, len) != 1)
    {
        std::printf("Condition check : FALSE.\nTransformation skipped.\n");
        return 0;
    }
    std::printf("Condition check : TRUE.\nApplying transformation...\n");

    TransformTextAsm(text, len);

    std::printf("Transformed text: %.*s\n", len, text);
    return 0;
}
