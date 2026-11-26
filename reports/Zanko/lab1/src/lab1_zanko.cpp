#include <iostream>
#include <string>
#include <chrono>
#include <cstring>

using namespace std;

string process_cpp(const string& str1, const string& str2) {
    string result = str1;
    size_t min_len = min(str1.length(), str2.length());

    for (size_t i = 0; i < min_len; ++i) {
        if (str1[i] == str2[i]) {
            result[i] = '0';
        }
    }
    return result;
}

void process_asm(const char* str1, const char* str2, char* result) {
    __asm {
        mov esi, str1
        mov edi, str2
        mov ebx, result

        compare_loop :
        mov al, [esi]
            mov cl, [edi]

            cmp al, 0
            je copy_rest_str1
            cmp cl, 0
            je copy_rest_str1

            cmp al, cl
            jne not_equal

            mov byte ptr[ebx], '0'
            jmp next_char

            not_equal :
        mov[ebx], al

            next_char :
        inc esi
            inc edi
            inc ebx
            jmp compare_loop

            copy_rest_str1 :
        cmp al, 0
            je done
            mov[ebx], al
            inc esi
            inc ebx
            mov al, [esi]
            jmp copy_rest_str1

            done :
        mov byte ptr[ebx], 0
    }
}

int main() {
    setlocale(LC_ALL, "Russian");

    string s1 = "programming";
    string s2 = "processing";

    cout << "Строка 1: " << s1 << endl;
    cout << "Строка 2: " << s2 << endl;

    auto start_cpp = chrono::high_resolution_clock::now();
    string result_cpp = process_cpp(s1, s2);
    auto end_cpp = chrono::high_resolution_clock::now();
    chrono::duration<double, milli> time_cpp = end_cpp - start_cpp;

    char* result_asm = new char[s1.length() + 1];
    strcpy_s(result_asm, s1.length() + 1, s1.c_str());

    auto start_asm = chrono::high_resolution_clock::now();
    process_asm(s1.c_str(), s2.c_str(), result_asm);
    auto end_asm = chrono::high_resolution_clock::now();
    chrono::duration<double, milli> time_asm = end_asm - start_asm;

    cout << "\n--- Результаты ---" << endl;
    cout << "Результат C++: " << result_cpp << endl;
    cout << "Результат ASM: " << result_asm << endl;
    cout << "Время C++: " << time_cpp.count() << " мс" << endl;
    cout << "Время ASM: " << time_asm.count() << " мс" << endl;

    delete[] result_asm;
    return 0;
}