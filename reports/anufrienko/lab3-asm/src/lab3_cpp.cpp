// lab3_main.cpp
// Лаб. №3. Вариант 1. Подсчёт вхождений заданного символа в строку текста.
// Алгоритм реализован в виде макроопределения COUNT_CHAR (см. lab3_asm.asm).

#include <cstdio>
#include <windows.h>

extern "C" int CountCharAsm(const char* text, int length, char target);   // обёртка над макросом COUNT_CHAR

const int MAX_LEN = 100;   // максимальная длина текста — константа, не зависящая от фактического ввода
const int THRESHOLD = 5;   

int main()
{
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);

    char buffer[MAX_LEN + 1];
    int  length = 0;
    bool tooLong = false;

    printf("Введите текст (не более %d символов, признак конца ввода - точка):\n", MAX_LEN);

    int ch;
    while ((ch = getchar()) != EOF && ch != '.')
    {
        if (length < MAX_LEN)
        {
            buffer[length] = (char)ch;
            ++length;
        }
        else
        {
            tooLong = true;
        }
    }

    // Сразу после точки в потоке ввода остаётся "хвостовой" \n (от Enter, которым точка была отправлена).
    
    // Съедаем его здесь же, иначе следующий getchar() ниже прочитает именно его, а не нужный символ.
    while ((ch = getchar()) != '\n' && ch != EOF) {}

    buffer[length] = '\0';

    if (length == 0 || tooLong)
    {
        printf("\nВведённая последовательность символов не является текстом ");
        printf("(текст должен быть непустым и не длиннее %d символов).\n", MAX_LEN);
        return 0;
    }

    printf("\nВведённый текст (%d симв.): %s\n", length, buffer);

    printf("Введите символ, вхождения которого нужно подсчитать: ");
    int targetInt = getchar();
    while (getchar() != '\n' && !feof(stdin)) {}   // съедаем остаток строки ввода

    if (targetInt == EOF)
    {
        printf("Символ не введён.\n");
        return 0;
    }

    char target = (char)targetInt;
    int count = CountCharAsm(buffer, length, target);

    // Выбор слова "всего"/"целых" в зависимости от того, превышает ли count порог THRESHOLD
    const char* amountWord = (count > THRESHOLD) ? "всего" : "целых";

    // Выбор окончания "раза"/"раз": "раза" только для count == 2, 3 или 4; во всех остальных случаях — "раз"
    const char* timesWord = (count >= 2 && count <= 4) ? "раза" : "раз";

    printf("Символ '%c' встречается в тексте %s %d %s.\n", target, amountWord, count, timesWord);

    return 0;
}