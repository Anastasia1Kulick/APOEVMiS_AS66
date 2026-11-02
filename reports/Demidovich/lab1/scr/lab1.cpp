#include <iostream>
#include <string>
#include <chrono>
#include <vector>
#include <cstring>

// 1. Реализация на чистом C++
void combineCpp(const char* s1, const char* s2, char* dest, int len) {
    for (int i = 0; i < len; ++i) {
        if (i % 2 == 0) {
            dest[i] = s1[i]; // 1-й, 3-й, 5-й символы (индексы 0, 2, 4...) из первой строки
        }
        else {
            dest[i] = s2[i]; // 2-й, 4-й, 6-й символы (индексы 1, 3, 5...) из второй строки
        }
    }
    dest[len] = '\0';
}

// 2. Реализация со встроенной ассемблерной вставкой (__asm)
void combineAsm(const char* s1, const char* s2, char* dest, int len) {
    __asm {
        mov esi, s1; esi = указатель на s1
        mov ebx, s2; ebx = указатель на s2
        mov edi, dest; edi = указатель на результирующую строку
        mov ecx, len; ecx = количество символов
        xor edx, edx; edx = индекс i = 0

        START_LOOP:
        cmp edx, ecx
            jge END_LOOP; если i >= len, завершить цикл

            test edx, 1; проверяем младший бит индекса(четность)
            jnz TAKE_FROM_S2; если не 0 (нечетный индекс 1, 3, 5...), берем из s2

            TAKE_FROM_S1 :
        mov al, [esi + edx]; берем байт из s1[i]
            jmp STORE_CHAR

            TAKE_FROM_S2 :
        mov al, [ebx + edx]; берем байт из s2[i]

            STORE_CHAR:
        mov[edi + edx], al; записываем в dest[i]
            inc edx; i++
            jmp START_LOOP

            END_LOOP :
        mov byte ptr[edi + edx], 0; ставим нулевой терминатор '\0'
    }
}

int main() {
    setlocale(LC_ALL, "Russian");

    // Демонстрация корректности работы
    const char* str1 = "1111111111";
    const char* str2 = "2222222222";
    int len = strlen(str1);

    char resCpp[100];
    char resAsm[100];

    combineCpp(str1, str2, resCpp, len);
    combineAsm(str1, str2, resAsm, len);

    std::cout << "--- Проверка работы функций ---\n";
    std::cout << "Строка 1: " << str1 << "\n";
    std::cout << "Строка 2: " << str2 << "\n";
    std::cout << "Результат C++: " << resCpp << "\n";
    std::cout << "Результат Asm: " << resAsm << "\n\n";

    // Тестирование быстродействия на большой строке
    const int TEST_LEN = 10000000; // 10 млн символов
    std::string bigStr1(TEST_LEN, 'A');
    std::string bigStr2(TEST_LEN, 'B');
    std::vector<char> bigDestCpp(TEST_LEN + 1);
    std::vector<char> bigDestAsm(TEST_LEN + 1);

    // Замер C++
    auto startCpp = std::chrono::high_resolution_clock::now();
    combineCpp(bigStr1.c_str(), bigStr2.c_str(), bigDestCpp.data(), TEST_LEN);
    auto endCpp = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::milli> elapsedCpp = endCpp - startCpp;

    // Замер ASM
    auto startAsm = std::chrono::high_resolution_clock::now();
    combineAsm(bigStr1.c_str(), bigStr2.c_str(), bigDestAsm.data(), TEST_LEN);
    auto endAsm = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::milli> elapsedAsm = endAsm - startAsm;

    std::cout << "--- Сравнение быстродействия (" << TEST_LEN << " символов) ---\n";
    std::cout << "Время работы C++: " << elapsedCpp.count() << " мс\n";
    std::cout << "Время работы Asm: " << elapsedAsm.count() << " мс\n";

    return 0;
}