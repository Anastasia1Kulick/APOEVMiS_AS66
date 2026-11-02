#include <iostream>
#include <cstring>
#include <chrono>

void replace_cpp(char* text) {
    for (int i = 0; text[i] != '\0'; i++) {
        if (text[i] == ' ') {
            text[i] = '\t';
        }
    }
}

void replace_asm(char* text) {
    __asm {
        mov eax, text
    next_char:
        cmp byte ptr [eax], 0
        je finish
        cmp byte ptr [eax], 32
        jne skip
        mov byte ptr [eax], 9
    skip:
        inc eax
        jmp next_char
    finish:
    }
}

int main() {
    char text[256];
    char cpp[256];
    char assembly[256];
    char buffer[256];
    const int repeats = 1000000;

    std::cout << "Lab 1. Variant 12: replace spaces with tabs.\n";
    std::cout << "Enter a string (up to 255 bytes): ";
    std::cin.getline(text, 256);
    if (!std::cin) {
        std::cout << "Input error: the string is too long or input ended.\n";
        return 1;
    }
    std::cout << '\n';

    std::strcpy(cpp, text);
    std::strcpy(assembly, text);
    replace_cpp(cpp);
    replace_asm(assembly);

    std::cout << "Original: [" << text << "]\n";
    std::cout << "C++:      [" << cpp << "]\n";
    std::cout << "ASM:      [" << assembly << "]\n";
    if (std::strcmp(cpp, assembly) != 0) {
        std::cout << "Results differ.\n";
        return 1;
    }
    std::cout << "Results match.\n";

    int size = static_cast<int>(std::strlen(text)) + 1;
    auto start = std::chrono::steady_clock::now();
    for (int i = 0; i < repeats; i++) {
        std::memcpy(buffer, text, size);
        replace_cpp(buffer);
    }
    auto finish = std::chrono::steady_clock::now();
    double cpp_time = std::chrono::duration<double, std::milli>(finish - start).count();
    std::cout << "C++ result: [" << buffer << "]\n";

    start = std::chrono::steady_clock::now();
    for (int i = 0; i < repeats; i++) {
        std::memcpy(buffer, text, size);
        replace_asm(buffer);
    }
    finish = std::chrono::steady_clock::now();
    double asm_time = std::chrono::duration<double, std::milli>(finish - start).count();
    std::cout << "ASM result: [" << buffer << "]\n";
    std::cout << "Calls per function: " << repeats << '\n';
    std::cout << "C++ time: " << cpp_time << " ms\n";
    std::cout << "ASM time: " << asm_time << " ms\n";
    return 0;
}
