#include <iostream>
#include <string>
#include <ctime>
#include <windows.h>
using namespace std;

void asmCombine(const char* s1, const char* s2, char* res) {
    __asm {
        push esi                        
        push edi                       

        mov esi, s1                   
        mov edi, res                
        xor ecx, ecx                  

        loop1 :
        mov al, [esi + ecx]             
            test al, al                   
            jz   end1                      
            test ecx, 1                   
            jnz  skip1                     
            mov[edi], al                   
            inc edi
            skip1 :
        inc ecx
            jmp loop1

            end1 :
        mov esi, s2                     
            xor ecx, ecx

            loop2 :
        mov al, [esi + ecx]
            test al, al
            jz   end2
            test ecx, 1                    
            jz   skip2                     
            mov[edi], al                   
            inc edi
            skip2 :
        inc ecx
            jmp loop2

            end2 :
        mov byte ptr[edi], 0         

            pop edi
            pop esi
    }
}

void cppCombine(const char* s1, const char* s2, char* res) {
    int k = 0;                              

    for (int i = 0; s1[i] != '\0'; ++i) {   
        if (i % 2 == 0) {                  
            res[k++] = s1[i];
        }
    }
    for (int i = 0; s2[i] != '\0'; ++i) {  
        if (i % 2 == 1) {                  
            res[k++] = s2[i];
        }
    }
    res[k] = '\0';
}

int main() {
    SetConsoleCP(65001);                    
    SetConsoleOutputCP(65001);

    const char* s1 = "pnreoukoupr";   
    const char* s2 = "bowrk2l2m8";   
    char res[128];

    asmCombine(s1, s2, res);
    cout << "[ASM]  s1 = \"" << s1 << "\"\n";
    cout << "[ASM]  s2 = \"" << s2 << "\"\n";
    cout << "[ASM]  результат: " << res << "\n\n";

    cppCombine(s1, s2, res);
    cout << "[C++]  s1 = \"" << s1 << "\"\n";
    cout << "[C++]  s2 = \"" << s2 << "\"\n";
    cout << "[C++]  результат: " << res << "\n\n";

    cout << "  >> Если всё верно, выше должно быть: prokuror228\n";
    cout << "  >> Если нет — значит где-то потерялся байт. Ищи его, он рядом.\n\n";

    const int N = 100000;               
    const int ITER = 5000;                 

    string a(N, 'A'), b(N, 'B');
    for (int i = 0; i < N; ++i) {
        a[i] = 'A' + (i % 26);             
        b[i] = 'a' + (i % 26);
    }

    string buf(N + 1, '\0');

    clock_t t1 = clock();
    for (int i = 0; i < ITER; ++i)
        asmCombine(a.c_str(), b.c_str(), &buf[0]);
    clock_t t2 = clock();

    clock_t t3 = clock();
    for (int i = 0; i < ITER; ++i)
        cppCombine(a.c_str(), b.c_str(), &buf[0]);
    clock_t t4 = clock();

    double asmSec = (double)(t2 - t1) / CLOCKS_PER_SEC;
    double cppSec = (double)(t4 - t3) / CLOCKS_PER_SEC;

    cout << "---------- замеры скорости ----------\n";
    cout << "ASM:  " << asmSec << " сек\n";
    cout << "C++:  " << cppSec << " сек\n";
    if (asmSec < cppSec)
        cout << "Вывод: ассемблер быстрее в " << (cppSec / asmSec) << " раз.\n";
    else if (cppSec < asmSec)
        cout << "Вывод: C++ быстрее в " << (asmSec / cppSec) << " раз. Ну и ладно.\n";
    else
        cout << "Вывод: ничья. Все молодцы.\n";

    cout << "\n[программа завершена, можно закрывать]\n";
    return 0;
}