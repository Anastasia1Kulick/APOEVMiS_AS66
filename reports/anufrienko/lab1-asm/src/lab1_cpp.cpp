// lab1_cpp.cpp
// Та же обработка строки (Вариант 1: реверс), реализованная на C++,
// для сравнения быстродействия с ассемблерной вставкой.

#include <cstddef>

void ReverseStringCpp(char* str)
{
    if (!str) return;

    size_t len = 0;
    while (str[len] != '\0') ++len;

    size_t left = 0;
    size_t right = (len == 0) ? 0 : len - 1;

    while (left < right)
    {
        char tmp = str[left];
        str[left] = str[right];
        str[right] = tmp;
        ++left;
        --right;
    }
}