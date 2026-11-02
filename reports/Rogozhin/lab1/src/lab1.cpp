#include <iostream>
#include <string>
#include <chrono>

// 1. C++ implementation
std::string combineHalvesCPP(const std::string& s1, const std::string& s2) {
    size_t len1 = s1.length();
    size_t len2 = s2.length();
    
    std::string half1 = s1.substr(0, (len1 + 1) / 2);
    std::string half2 = s2.substr(0, (len2 + 1) / 2);
    
    return half1 + half2;
}

// 2. Assembler implementation (x86 MSVC inline assembly)
void combineHalvesAsm(const char* src1, const char* src2, char* dest) {
    __asm {
        push esi
        push edi
        push ebx
        push ecx

        // --- Process first string (src1) ---
        mov esi, src1       
        mov edi, dest       

        xor ecx, ecx        
    find_len1:
        mov al, [esi + ecx]
        cmp al, 0
        je calc_half1
        inc ecx
        jmp find_len1

    calc_half1:
        inc ecx
        shr ecx, 1          
        mov ebx, ecx        

        test ecx, ecx
        jz copy_second_init
        cld
        rep movsb           

    copy_second_init:
        // --- Process second string (src2) ---
        mov esi, src2       
        
        xor ecx, ecx
    find_len2:
        mov al, [esi + ecx]
        cmp al, 0
        je calc_half2
        inc ecx
        jmp find_len2

    calc_half2:
        inc ecx
        shr ecx, 1          

        test ecx, ecx
        jz finalize
        rep movsb

    finalize:
        mov byte ptr [edi], 0

        pop ecx
        pop ebx
        pop edi
        pop esi
    }
}

int main() {
    std::string str1 = "Programming";
    std::string str2 = "Assembler";

    std::cout << "String 1: " << str1 << std::endl;
    std::cout << "String 2: " << str2 << std::endl;
    std::cout << "----------------------------------------" << std::endl;

    // C++ benchmark
    auto startCPP = std::chrono::high_resolution_clock::now();
    std::string resultCPP = combineHalvesCPP(str1, str2);
    auto endCPP = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::micro> durationCPP = endCPP - startCPP;

    std::cout << "Result (C++): " << resultCPP << std::endl;
    std::cout << "Time C++: " << durationCPP.count() << " us" << std::endl;

    // Asm benchmark
    char buffer[256] = { 0 };
    auto startAsm = std::chrono::high_resolution_clock::now();
    combineHalvesAsm(str1.c_str(), str2.c_str(), buffer);
    auto endAsm = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double, std::micro> durationAsm = endAsm - startAsm;

    std::cout << "Result (Asm): " << buffer << std::endl;
    std::cout << "Time Asm: " << durationAsm.count() << " us" << std::endl;

    return 0;
}