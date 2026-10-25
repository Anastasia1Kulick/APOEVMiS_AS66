#include <iostream>
#include <chrono>
#include <cstring>
#include <clocale>

using namespace std;

extern "C" void combineStringsAsm(const char* s1, const char* s2, char* result) {
    __asm {
        push    esi
        push    edi
        push    ebx

        mov     esi, s1
        mov     edi, s2
        mov     ebx, result

        xor ecx, ecx

        loop_s1 :
        mov     al, [esi + ecx]
            test    al, al
            jz      loop_s2_start

            test    ecx, 1
            jnz     skip_s1

            mov[ebx], al
            inc     ebx

            skip_s1 :
        inc     ecx
            jmp     loop_s1

            loop_s2_start :
        xor ecx, ecx

            loop_s2 :
        mov     al, [edi + ecx]
            test    al, al
            jz      done

            test    ecx, 1
            jz      skip_s2

            mov[ebx], al
            inc     ebx

            skip_s2 :
        inc     ecx
            jmp     loop_s2

            done :
        mov     byte ptr[ebx], 0

            pop     ebx
            pop     edi
            pop     esi
    }
}

void combineStringsCpp(const char* s1, const char* s2, char* result) {
    int k = 0;

    for (int i = 0; s1[i] != '\0'; ++i) {
        if (i % 2 == 0) {
            result[k++] = s1[i];
        }
    }

    for (int i = 0; s2[i] != '\0'; ++i) {
        if (i % 2 != 0) {
            result[k++] = s2[i];
        }
    }

    result[k] = '\0';
}

int main() {
    setlocale(LC_ALL, "Russian");

    const char* s1 = "ABCDEFGHIJ";
    const char* s2 = "0123456789";

    char resultAsm[256] = { 0 };
    char resultCpp[256] = { 0 };

    combineStringsAsm(s1, s2, resultAsm);
    combineStringsCpp(s1, s2, resultCpp);

    cout << "String 1: " << s1 << endl;
    cout << "String 2: " << s2 << endl;
    cout << "Result (ASM): " << resultAsm << endl;
    cout << "Result (C++): " << resultCpp << endl;

    if (strcmp(resultAsm, resultCpp) == 0) {
        cout << "[OK] Results match!" << endl << endl;
    }
    else {
        cout << "[ERROR] Results differ!" << endl << endl;
    }

    const int N = 1000000;

    for (int i = 0; i < 10000; ++i) {
        combineStringsAsm(s1, s2, resultAsm);
    }
    for (int i = 0; i < 10000; ++i) {
        combineStringsCpp(s1, s2, resultCpp);
    }

    auto start = chrono::high_resolution_clock::now();
    for (int i = 0; i < N; ++i) {
        combineStringsAsm(s1, s2, resultAsm);
    }
    auto end = chrono::high_resolution_clock::now();
    long long asmNs = chrono::duration_cast<chrono::nanoseconds>(end - start).count();

    start = chrono::high_resolution_clock::now();
    for (int i = 0; i < N; ++i) {
        combineStringsCpp(s1, s2, resultCpp);
    }
    end = chrono::high_resolution_clock::now();
    long long cppNs = chrono::duration_cast<chrono::nanoseconds>(end - start).count();

    cout << "Iterations: " << N << endl;
    cout << "ASM total:  " << asmNs << " ns  (" << asmNs / N << " ns/call)" << endl;
    cout << "C++ total:  " << cppNs << " ns  (" << cppNs / N << " ns/call)" << endl;

    double ratio = (double)cppNs / (double)asmNs;
    cout << "Ratio (C++ / ASM): " << ratio << endl;

    volatile char sink = resultAsm[0] ^ resultCpp[0];
    (void)sink;

    return 0;
}