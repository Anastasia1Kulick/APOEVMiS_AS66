// lab3_main.cpp
// Лабораторная работа №3, вариант 9. Куган Н. Л., АС-66. Платформа: x86.
// Ввод строки слов и символа, вызов макроопределения, вывод результата.
//
// Задание: задана строка слов (слово - последовательность символов между
// пробелами). Из строки удалить слова, начинающиеся с заданного символа.
// Алгоритм реализован в виде макроопределения REMOVE_WORDS (см. lab3_asm.asm).
// Пробелы между словами не изменяются, регистр символа учитывается.
//
// Строки для проверки (вводить в консоль вместе с точкой; затем символ):
//   apple banana avocado cherry.   символ a  -> " banana  cherry"
//   Привет мир при пока.           символ п  -> "Привет мир  " (удалены "при" и "пока")
//   Привет мир при пока.           символ П  -> " мир при пока"
//   one two three.                 символ x  -> "one two three" (без изменений)
//   abc abd abe.                   символ a  -> "  " (удалены все слова)
//   a1 b2 a3 c4.                   символ a  -> " b2  c4"
//   hello.                         символ h  -> "" (пустая строка)
//   .                              -> ошибка: пустой ввод
//   ТЕКСТ БЕЗ ТОЧКИ                -> ошибка: нет точки (Enter до точки)

#include <cstdio>
#include <windows.h>

#ifndef _M_IX86
#error Assembly module is built with ml.exe (x86 only): choose platform "x86" (Win32).
#endif

// реализация в lab3_asm.asm: обёртка над макросом REMOVE_WORDS, возвращает новую длину текста
extern "C" int RemoveWordsAsm(char* text, int len, char target);

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
    std::printf(" Lab 3, variant 9. Macro definitions\n");
    std::printf(" Task: the text is a string of words (separated by\n");
    std::printf("       spaces). Delete all words that begin with\n");
    std::printf("       the given character.\n");
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

    // после точки в потоке остаётся остаток строки (Enter) - убираем его,
    // иначе следующий getchar() прочитает его вместо искомого символа
    int c;
    while ((c = std::getchar()) != '\n' && c != EOF)
    {
    }

    std::printf("Enter the character that words must begin with:\n> ");
    int t = std::getchar();
    if (t == '\n' || t == EOF)
    {
        std::printf("\nError: character is not entered!\n");
        return 0;
    }
    char target = (char)t;

    std::printf("\nOriginal text   : %.*s\n", len, text);
    std::printf("Character       : '%c'\n", target);

    int newLen = RemoveWordsAsm(text, len, target);

    std::printf("Result length   : %d\n", newLen);
    std::printf("Transformed text: [%.*s]\n", newLen, text);
    return 0;
}
