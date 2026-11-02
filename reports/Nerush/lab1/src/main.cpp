#include <iostream>
#include <cstring>
#include <chrono>
#include <Windows.h>

using namespace std;
using namespace std::chrono;

#define MAX_LEN    128
#define ITERATIONS 1000000

// Обработка строк на ассемблере
// Меняет местами 1-ю строку с 4-й и 2-ю с 3-й (побайтно по всему буферу)
void swapAsm(char* s1, char* s2, char* s3, char* s4)
{
    __asm {
        mov esi, s1; ESI = адрес 1 - й строки
        mov edi, s4; EDI = адрес 4 - й строки
        mov ebx, s2; EBX = адрес 2 - й строки
        mov edx, s3; EDX = адрес 3 - й строки
        xor ecx, ecx; ECX = 0 (индекс текущего символа)

        SwapLoop:
        ; --- обмен символов 1 - й и 4 - й строк-- -
            mov al, [esi + ecx]; AL = s1[i]
            mov ah, [edi + ecx]; AH = s4[i]
            mov[esi + ecx], ah; s1[i] = AH
            mov[edi + ecx], al; s4[i] = AL

            ; --- обмен символов 2 - й и 3 - й строк-- -
            mov al, [ebx + ecx]; AL = s2[i]
            mov ah, [edx + ecx]; AH = s3[i]
            mov[ebx + ecx], ah; s2[i] = AH
            mov[edx + ecx], al; s3[i] = AL

            inc ecx; переходим к следующему символу
            cmp ecx, MAX_LEN; дошли до конца буфера ?
            jb SwapLoop; если нет — продолжаем цикл
    }
}

// Та же обработка на C++
void swapCpp(char* s1, char* s2, char* s3, char* s4)
{
    for (int i = 0; i < MAX_LEN; i++) {
        char t = s1[i]; s1[i] = s4[i]; s4[i] = t;
        t = s2[i];      s2[i] = s3[i]; s3[i] = t;
    }
}

void printStrings(const char* title, char s[4][MAX_LEN])
{
    cout << title << endl;
    for (int i = 0; i < 4; i++)
        cout << "  Строка " << i + 1 << ": " << s[i] << endl;
}

int main()
{
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    char src[4][MAX_LEN] = {};
    char resCpp[4][MAX_LEN];
    char resAsm[4][MAX_LEN];

    for (int i = 0; i < 4; i++) {
        cout << "Введите строку " << i + 1 << ": ";
        cin.getline(src[i], MAX_LEN);
    }

    memcpy(resCpp, src, sizeof(src));
    memcpy(resAsm, src, sizeof(src));

    // однократная обработка для вывода результата
    swapCpp(resCpp[0], resCpp[1], resCpp[2], resCpp[3]);
    swapAsm(resAsm[0], resAsm[1], resAsm[2], resAsm[3]);

    cout << endl;
    printStrings("Исходные строки:", src);
    printStrings("\nРезультат C++:", resCpp);
    printStrings("\nРезультат ASM:", resAsm);

    // замер быстродействия (многократный вызов)
    char work[4][MAX_LEN];
    memcpy(work, src, sizeof(src));

    auto startCpp = high_resolution_clock::now();
    for (int k = 0; k < ITERATIONS; k++)
        swapCpp(work[0], work[1], work[2], work[3]);
    auto endCpp = high_resolution_clock::now();

    auto startAsm = high_resolution_clock::now();
    for (int k = 0; k < ITERATIONS; k++)
        swapAsm(work[0], work[1], work[2], work[3]);
    auto endAsm = high_resolution_clock::now();

    long long timeCpp = duration_cast<microseconds>(endCpp - startCpp).count();
    long long timeAsm = duration_cast<microseconds>(endAsm - startAsm).count();

    cout << "\nЧисло повторов: " << ITERATIONS << endl;
    cout << "Время C++: " << timeCpp << " мкс ("
        << timeCpp * 1000.0 / ITERATIONS << " нс на вызов)" << endl;
    cout << "Время ASM: " << timeAsm << " мкс ("
        << timeAsm * 1000.0 / ITERATIONS << " нс на вызов)" << endl;

    return 0;
}