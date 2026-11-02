// lab2_main.cpp
// Лаб. №2. Вариант 1. Ввод текста, проверка условия, преобразование, вывод.

#include <cstdio>
#include <windows.h>

extern "C" int  CheckConditionAsm(const char* text, int length);   // реализация в lab2_asm.asm
extern "C" void TransformTextAsm(char* text, int length);          // реализация в lab2_asm.asm

const int MAX_LEN = 100;   // максимальная длина текста — константа, не зависящая от фактического ввода

int main()
{
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);

    char buffer[MAX_LEN + 1];   // +1 под завершающий 0 для printf("%s", ...)
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
            tooLong = true;   // лимит превышен; дочитываем до точки, но текст уже считается невалидным
        }
    }
    buffer[length] = '\0';

    bool isValidText = (length > 0) && !tooLong;

    if (!isValidText)
    {
        printf("\nВведённая последовательность символов не является текстом ");
        printf("(текст должен быть непустым и не длиннее %d символов).\n", MAX_LEN);
        return 0;
    }

    printf("\nВведённый текст (%d симв.): %s\n", length, buffer);
    printf("Проверяемое условие: текст оканчивается прописной латинской буквой,\n");
    printf("которая больше нигде в тексте не встречается.\n");

    int conditionMet = CheckConditionAsm(buffer, length);

    if (!conditionMet)
    {
        printf("Условие НЕ выполнено - текст не преобразуется.\n");
        return 0;
    }

    printf("Условие выполнено.\n");
    printf("Правило преобразования: каждая ненулевая цифра заменяется на\n");
    printf("соответствующую строчную латинскую букву (1->a, 2->b, ..., 9->i).\n");

    TransformTextAsm(buffer, length);

    printf("Преобразованный текст: %s\n", buffer);

    return 0;
}