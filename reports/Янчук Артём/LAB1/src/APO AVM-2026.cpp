#include "iostream"
#include "cstring"
#include "chrono"

using namespace std;

void shiftForwardCpp(char* myStr, int k) {
    int len = strlen(myStr);
    if (len <= 1 || k <= 0) return;

    k = k % len;
    if (k == 0) return;

    for (int step = 0; step < k; ++step) {
        char lastChar = myStr[len - 1];

        for (int i = len - 1; i > 0; --i) {
            myStr[i] = myStr[i - 1];
        }

        myStr[0] = lastChar;
    }
}

void shiftForwardAsm(char* myStr, int k) {
    int len = strlen(myStr);
    if (len <= 1 || k <= 0) return;

    k = k % len;
    if (k == 0) return;

    __asm {
        mov esi, myStr
        mov edx, k

        outer_loop :
        mov ecx, len
            dec ecx

            mov al, [esi + ecx]

            shift_loop :
            test ecx, ecx
            jz end_shift_loop

            mov bl, [esi + ecx - 1]
            mov[esi + ecx], bl

            dec ecx
            jmp shift_loop

            end_shift_loop :
        mov[esi], al

            dec edx
            test edx, edx
            jnz outer_loop
    }
}

int main() {
    setlocale(LC_ALL, "Russian");

    char originalStr[] = "HelloWorld";
    int shiftCount = 0;

    cout << "Исходная строка: " << originalStr << "\n";
    cout << "Введите количество позиций для сдвига: ";
    cin >> shiftCount;
    cout << "\n";

    char strCpp[50];
    strcpy_s(strCpp, 50, originalStr);
    shiftForwardCpp(strCpp, shiftCount);
    cout << "Результат C++:   " << strCpp << "\n";

    char strAsm[50];
    strcpy_s(strAsm, 50, originalStr);
    shiftForwardAsm(strAsm, shiftCount);
    cout << "Результат Asm:   " << strAsm << "\n\n";

    const int iterations = 1000000;
    char tempStr[50];

    strcpy_s(tempStr, 50, originalStr);
    auto startCpp = chrono::high_resolution_clock::now();
    for (int i = 0; i < iterations; ++i) {
        shiftForwardCpp(tempStr, shiftCount);
    }
    auto endCpp = chrono::high_resolution_clock::now();
    auto durationCpp = endCpp - startCpp;

    strcpy_s(tempStr, 50, originalStr);
    auto startAsm = chrono::high_resolution_clock::now();
    for (int i = 0; i < iterations; ++i) {
        shiftForwardAsm(tempStr, shiftCount);
    }
    auto endAsm = chrono::high_resolution_clock::now();
    auto durationAsm = endAsm - startAsm;

    cout << "=== Сравнение быстродействия (" << iterations << " итераций) ===\n";
    cout << "Время C++ (в тактах процессора): " << durationCpp.count() << "\n";
    cout << "Время Asm (в тактах процессора): " << durationAsm.count() << "\n";

    return 0;
}