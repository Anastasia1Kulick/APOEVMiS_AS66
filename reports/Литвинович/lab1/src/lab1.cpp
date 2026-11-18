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
    // x64 машинный код для Windows x64 ABI (rcx = str1, rdx = str2, r8 = dst):
    // Вычисляет длины через repne scasb и копирует половины через rep movsb
    static const unsigned char code[] =
    {
        0x57, 0x56, 0x48, 0x89, 0xCF, 0x48, 0x83, 0xC9, 0xFF, 0x30, 0xC0, 0xFC,
        0xF2, 0xAE, 0x48, 0xF7, 0xD1, 0x48, 0xFF, 0xC9, 0x49, 0x89, 0xC9, 0x48,
        0x89, 0xD7, 0x48, 0x83, 0xC9, 0xFF, 0xF2, 0xAE, 0x48, 0xF7, 0xD1, 0x48,
        0xFF, 0xC9, 0x49, 0x89, 0xCA, 0x4C, 0x89, 0xC7, 0x48, 0x89, 0xCE, 0x49,
        0xD1, 0xE9, 0x4C, 0x89, 0xC9, 0xF3, 0xA4, 0x49, 0x89, 0xD1, 0x49, 0xD1,
        0xE9, 0x4C, 0x89, 0xD6, 0x4C, 0x01, 0xCE, 0x4C, 0x89, 0xD1, 0x4C, 0x29,
        0xC9, 0xF3, 0xA4, 0xAA, 0x5E, 0x5F, 0xC3
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

        ; Вычисление длины str1 -> ebx
        mov edi, str1
        mov ecx, 0FFFFFFFFh
        xor al, al
        repne scasb
        not ecx
        dec ecx
        mov ebx, ecx

        ; Вычисление длины str2 -> edx
        mov edi, str2
        mov ecx, 0FFFFFFFFh
        repne scasb
        not ecx
        dec ecx
        mov edx, ecx

        ; Копирование первой половины str1 (len1 / 2 символов) в dst
        mov edi, dst
        mov esi, str1
        mov ecx, ebx
        shr ecx, 1
        rep movsb

        ; Копирование второй половины str2 (начиная с len2 / 2) в dst
        mov eax, edx
        shr eax, 1
        mov esi, str2
        add esi, eax
        mov ecx, edx
        sub ecx, eax
        rep movsb

        ; Запись нулевого терминатора (al == 0)
        stosb
    }
}

#else
#error Only x86 and x64 are supported
#endif

void combine_halves_cpp(const char* str1, const char* str2, char* dst)
{
    size_t len1 = strlen(str1);
    size_t len2 = strlen(str2);

    size_t half1 = len1 / 2;
    size_t start2 = len2 / 2;
    size_t rem2 = len2 - start2;

    memcpy(dst, str1, half1);
    memcpy(dst + half1, str2 + start2, rem2);
    dst[half1 + rem2] = '\0';
}

const char* yes_no(bool value)
{
    return value ? "yes" : "no";
}

void print_string(const char* title, const char* str)
{
    cout << title << "[" << str << "]  (length: " << strlen(str) << ")" << endl;
}

void fill_test_data(vector<char>& data, unsigned int seed)
{
    mt19937 gen(seed);
    uniform_int_distribution<int> letter(0, 25);

    for (size_t i = 0; i + 1 < data.size(); ++i)
        data[i] = static_cast<char>('a' + letter(gen));

    data[data.size() - 1] = '\0';
}

double measure(CombineFunc func, const vector<char>& src1,
               const vector<char>& src2, vector<char>& dst)
{
    double total = 0.0;

    for (int run = 0; run < BENCH_RUNS; ++run)
    {
        auto start = chrono::steady_clock::now();
        func(src1.data(), src2.data(), dst.data());
        auto finish = chrono::steady_clock::now();

        total += chrono::duration<double, milli>(finish - start).count();
    }

    return total / BENCH_RUNS;
}

void run_benchmark()
{
    vector<char> src1(BENCH_LEN);
    vector<char> src2(BENCH_LEN);
    vector<char> dst_asm(BENCH_LEN);
    vector<char> dst_cpp(BENCH_LEN);

    fill_test_data(src1, 12345);
    fill_test_data(src2, 67890);

    cout << endl << "Performance comparison" << endl;
    cout << "Test strings length: " << BENCH_LEN - 1 << " characters each" << endl;
    cout << "Number of runs: " << BENCH_RUNS << endl;

    double time_asm = measure(combine_halves_asm, src1, src2, dst_asm);
    double time_cpp = measure(combine_halves_cpp, src1, src2, dst_cpp);

    bool same = strcmp(dst_asm.data(), dst_cpp.data()) == 0;
    cout << "Function results match: " << yes_no(same) << endl;
    cout << "Assembly insert: " << time_asm << " ms" << endl;
    cout << "C++ function:    " << time_cpp << " ms" << endl;
}

int main()
{
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    cout << "Laboratory work No. 1. Variant 11" << endl;
    cout << "Task: combine the first half of string 1 with" << endl;
    cout << "the second half of string 2." << endl << endl;

    char input1[MAX_LEN];
    char input2[MAX_LEN];

    cout << "Enter string 1 (at most " << MAX_LEN - 1 << " characters):" << endl;
    cin.getline(input1, MAX_LEN);
    if (cin.fail())
    {
        cin.clear();
        cin.ignore(10000, '\n');
    }

    cout << "Enter string 2 (at most " << MAX_LEN - 1 << " characters):" << endl;
    cin.getline(input2, MAX_LEN);
    if (cin.fail())
    {
        cin.clear();
        cin.ignore(10000, '\n');
    }

    char res_asm[MAX_LEN];
    char res_cpp[MAX_LEN];

    combine_halves_asm(input1, input2, res_asm);
    combine_halves_cpp(input1, input2, res_cpp);

    cout << endl;
    print_string("String 1:                ", input1);
    print_string("String 2:                ", input2);
    print_string("Result (asm insert):     ", res_asm);
    print_string("Result (C++):            ", res_cpp);
    bool same = strcmp(res_asm, res_cpp) == 0;
    cout << "Results match: " << yes_no(same) << endl;

    run_benchmark();

    return 0;
}