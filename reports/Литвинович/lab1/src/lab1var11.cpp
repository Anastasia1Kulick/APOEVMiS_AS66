#include <iostream>
#include <vector>
#include <random>
#include <chrono>
#include <cstring>
#include <windows.h>

using namespace std;

using CombineFunc = void (*)(const char*, const char*, char*);

const int MAX_LEN = 256;
const size_t BENCH_LEN = 20000000;
const int BENCH_RUNS = 10;

#if defined(_M_X64)

static CombineFunc load_asm()
{
    // Windows x64 ABI (MSVC): RCX = str1, RDX = str2, R8 = dst
    static const unsigned char code[] =
    {
        0x53,                               // push rbx
        0x56,                               // push rsi
        0x57,                               // push rdi
        0x49, 0x89, 0xCB,                   // mov r11, rcx        ; str1
        0x49, 0x89, 0xD2,                   // mov r10, rdx        ; str2
        0x4D, 0x89, 0xC1,                   // mov r9, r8          ; dst
        0xFC,                               // cld

        // len1 = strlen(str1)
        0x4C, 0x89, 0xDF,                   // mov rdi, r11
        0x48, 0xC7, 0xC1, 0xFF, 0xFF, 0xFF, 0xFF, // mov rcx, -1
        0x30, 0xC0,                         // xor al, al
        0xF2, 0xAE,                         // repne scasb
        0x48, 0xF7, 0xD1,                   // not rcx
        0x48, 0xFF, 0xC9,                   // dec rcx             ; rcx = len1
        0x48, 0xD1, 0xE9,                   // shr rcx, 1          ; rcx = len1 / 2

        // copy first half of str1 -> dst
        0x4C, 0x89, 0xDE,                   // mov rsi, r11
        0x4C, 0x89, 0xCF,                   // mov rdi, r9
        0xF3, 0xA4,                         // rep movsb
        0x49, 0x89, 0xFB,                   // mov r11, rdi        ; save current dst

        // len2 = strlen(str2)
        0x4C, 0x89, 0xD7,                   // mov rdi, r10
        0x48, 0xC7, 0xC1, 0xFF, 0xFF, 0xFF, 0xFF, // mov rcx, -1
        0x30, 0xC0,                         // xor al, al
        0xF2, 0xAE,                         // repne scasb
        0x48, 0xF7, 0xD1,                   // not rcx
        0x48, 0xFF, 0xC9,                   // dec rcx             ; rcx = len2
        0x48, 0x89, 0xC8,                   // mov rax, rcx
        0x48, 0xD1, 0xE8,                   // shr rax, 1          ; rax = len2 / 2
        0x48, 0x29, 0xC1,                   // sub rcx, rax        ; rcx = len2 - len2 / 2

        // copy second half of str2 -> dst
        0x4C, 0x89, 0xD6,                   // mov rsi, r10
        0x48, 0x01, 0xC6,                   // add rsi, rax        ; str2 + len2 / 2
        0x4C, 0x89, 0xDF,                   // mov rdi, r11
        0xF3, 0xA4,                         // rep movsb

        // null terminator
        0x30, 0xC0,                         // xor al, al
        0xAA,                               // stosb

        0x5F,                               // pop rdi
        0x5E,                               // pop rsi
        0x5B,                               // pop rbx
        0xC3                                // ret
    };

    void* mem = VirtualAlloc(nullptr, sizeof(code), MEM_COMMIT | MEM_RESERVE,
                             PAGE_EXECUTE_READWRITE);
    memcpy(mem, code, sizeof(code));
    FlushInstructionCache(GetCurrentProcess(), mem, sizeof(code));
    return reinterpret_cast<CombineFunc>(mem);
}

static const CombineFunc asm_impl = load_asm();

void combine_halves_asm(const char* str1, const char* str2, char* dst)
{
    asm_impl(str1, str2, dst);
}

#elif defined(_M_IX86)

void combine_halves_asm(const char* str1, const char* str2, char* dst)
{
    __asm
    {
        cld

        // Вычисляем длину первой строки: len1 = strlen(str1)
        mov edi, str1
        mov ecx, -1
        xor al, al
        repne scasb
        not ecx
        dec ecx
        shr ecx, 1          // ecx = len1 / 2

        // Копируем первую половину str1 в dst
        mov esi, str1
        mov edi, dst
        rep movsb
        mov ebx, edi        // сохраняем текущую позицию записи в dst

        // Вычисляем длину второй строки: len2 = strlen(str2)
        mov edi, str2
        mov ecx, -1
        xor al, al
        repne scasb
        not ecx
        dec ecx
        mov eax, ecx
        shr eax, 1          // eax = len2 / 2 (начало второй половины)
        sub ecx, eax        // ecx = len2 - len2 / 2 (длина второй половины)

        // Копируем вторую половину str2 в dst
        mov esi, str2
        add esi, eax
        mov edi, ebx
        rep movsb

        // Записываем завершающий нулевой символ
        xor al, al
        stosb
    }
}

#else
#error Only MSVC x86 and x64 are supported
#endif

void combine_halves_cpp(const char* str1, const char* str2, char* dst)
{
    size_t len1 = strlen(str1);
    size_t half1 = len1 / 2;

    size_t len2 = strlen(str2);
    size_t start2 = len2 / 2;
    size_t second_half2 = len2 - start2;

    memcpy(dst, str1, half1);
    memcpy(dst + half1, str2 + start2, second_half2);
    dst[half1 + second_half2] = '\0';
}

const char* yes_no(bool value)
{
    return value ? "yes" : "no";
}

void print_string(const char* title, const char* str)
{
    cout << title << "[" << str << "]  (length: " << strlen(str) << ")" << endl;
}

void fill_test_data(vector<char>& data1, vector<char>& data2)
{
    mt19937 gen(12345);
    uniform_int_distribution<int> letter(0, 25);

    for (size_t i = 0; i + 1 < data1.size(); ++i)
    {
        data1[i] = static_cast<char>('a' + letter(gen));
        data2[i] = static_cast<char>('A' + letter(gen));
    }

    data1[data1.size() - 1] = '\0';
    data2[data2.size() - 1] = '\0';
}

double measure(CombineFunc func, const vector<char>& s1,
               const vector<char>& s2, vector<char>& dst)
{
    double total = 0.0;

    for (int run = 0; run < BENCH_RUNS; ++run)
    {
        auto start = chrono::steady_clock::now();
        func(s1.data(), s2.data(), dst.data());
        auto finish = chrono::steady_clock::now();

        total += chrono::duration<double, milli>(finish - start).count();
    }

    return total / BENCH_RUNS;
}

void run_benchmark()
{
    vector<char> s1(BENCH_LEN);
    vector<char> s2(BENCH_LEN);
    vector<char> res_asm(BENCH_LEN);
    vector<char> res_cpp(BENCH_LEN);

    fill_test_data(s1, s2);

    cout << endl << "Performance comparison" << endl;
    cout << "Test string length: " << BENCH_LEN - 1 << " characters" << endl;
    cout << "Number of runs: " << BENCH_RUNS << endl;

    double time_asm = measure(combine_halves_asm, s1, s2, res_asm);
    double time_cpp = measure(combine_halves_cpp, s1, s2, res_cpp);

    bool same = strcmp(res_asm.data(), res_cpp.data()) == 0;
    cout << "Function results match: " << yes_no(same) << endl;
    cout << "Assembly insert: " << time_asm << " ms" << endl;
    cout << "C++ function:    " << time_cpp << " ms" << endl;
}

int main()
{
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    cout << "Laboratory work No. 1. Variant 11" << endl;
    cout << "Task: combine the first half of string 1" << endl;
    cout << "with the second half of string 2." << endl << endl;

    char str1[MAX_LEN];
    char str2[MAX_LEN];

    cout << "Enter first string (at most " << MAX_LEN - 1 << " characters):" << endl;
    cin.getline(str1, MAX_LEN);
    if (cin.fail())
    {
        cin.clear();
        cin.ignore(10000, '\n');
        cout << "The string is too long, its first part is used." << endl;
    }

    cout << "Enter second string (at most " << MAX_LEN - 1 << " characters):" << endl;
    cin.getline(str2, MAX_LEN);
    if (cin.fail())
    {
        cin.clear();
        cin.ignore(10000, '\n');
        cout << "The string is too long, its first part is used." << endl;
    }

    char res_asm[MAX_LEN];
    char res_cpp[MAX_LEN];

    combine_halves_asm(str1, str2, res_asm);
    combine_halves_cpp(str1, str2, res_cpp);

    cout << endl;
    print_string("First string:            ", str1);
    print_string("Second string:           ", str2);
    print_string("Result (asm insert):     ", res_asm);
    print_string("Result (C++):            ", res_cpp);
    bool same = strcmp(res_asm, res_cpp) == 0;
    cout << "Results match: " << yes_no(same) << endl;

    run_benchmark();

    return 0;
}
