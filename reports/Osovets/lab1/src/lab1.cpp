#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <random>
#include <string>
#include <vector>

#if defined(_MSC_VER)
#define NOINLINE __declspec(noinline)
#else
#define NOINLINE __attribute__((noinline))
#endif

NOINLINE void reverse_asm(char32_t* s, std::size_t n)
{
#if defined(_MSC_VER) && defined(_M_IX86)
    unsigned int len = static_cast<unsigned int>(n);
    __asm {
        mov  ecx, len
        test ecx, ecx
        jz   finish
        mov  esi, s
        lea  edi, [esi + ecx*4 - 4]
    swap_loop:
        cmp  esi, edi
        jae  finish
        mov  eax, [esi]
        mov  edx, [edi]
        mov  [esi], edx
        mov  [edi], eax
        add  esi, 4
        sub  edi, 4
        jmp  swap_loop
    finish:
    }
#elif defined(__aarch64__)
    char32_t* left = s;
    char32_t* right = s;
    std::uint32_t a, b;
    __asm__ volatile(
        "cbz   %[n], 2f\n"
        "add   %[r], %[l], %[n], lsl #2\n"
        "sub   %[r], %[r], #4\n"
        "1:\n"
        "cmp   %[l], %[r]\n"
        "b.hs  2f\n"
        "ldr   %w[a], [%[l]]\n"
        "ldr   %w[b], [%[r]]\n"
        "str   %w[b], [%[l]], #4\n"
        "str   %w[a], [%[r]], #-4\n"
        "b     1b\n"
        "2:\n"
        : [l] "+r"(left), [r] "+r"(right), [a] "=&r"(a), [b] "=&r"(b)
        : [n] "r"(n)
        : "cc", "memory");
#else
#error "Ассемблерная вставка написана для MSVC x86 (Win32) и ARM64 (clang/gcc)"
#endif
}

NOINLINE void reverse_cpp(char32_t* s, std::size_t n)
{
    if (n == 0)
        return;
    std::size_t i = 0, j = n - 1;
    while (i < j) {
        char32_t t = s[i];
        s[i] = s[j];
        s[j] = t;
        ++i;
        --j;
    }
}

static std::u32string from_utf8(const std::string& in)
{
    std::u32string out;
    for (std::size_t i = 0; i < in.size();) {
        unsigned char c = static_cast<unsigned char>(in[i]);
        int extra = c < 0x80 ? 0 : (c >> 5) == 0x6 ? 1 : (c >> 4) == 0xE ? 2 : (c >> 3) == 0x1E ? 3 : -1;
        char32_t cp = extra == 0 ? c : extra == 1 ? (c & 0x1F) : extra == 2 ? (c & 0x0F) : (c & 0x07);
        bool ok = extra >= 0 && i + extra < in.size() + (extra == 0);
        for (int k = 1; ok && k <= extra; ++k) {
            unsigned char cc = static_cast<unsigned char>(in[i + k]);
            if ((cc & 0xC0) != 0x80)
                ok = false;
            else
                cp = (cp << 6) | (cc & 0x3F);
        }
        if (!ok) {
            out.push_back(0xFFFD);
            ++i;
        } else {
            out.push_back(cp);
            i += extra + 1;
        }
    }
    return out;
}

static std::string to_utf8(const std::u32string& in)
{
    std::string out;
    for (char32_t cp : in) {
        if (cp < 0x80) {
            out += static_cast<char>(cp);
        } else if (cp < 0x800) {
            out += static_cast<char>(0xC0 | (cp >> 6));
            out += static_cast<char>(0x80 | (cp & 0x3F));
        } else if (cp < 0x10000) {
            out += static_cast<char>(0xE0 | (cp >> 12));
            out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
            out += static_cast<char>(0x80 | (cp & 0x3F));
        } else {
            out += static_cast<char>(0xF0 | (cp >> 18));
            out += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
            out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
            out += static_cast<char>(0x80 | (cp & 0x3F));
        }
    }
    return out;
}

static void show(const std::string& text)
{
    std::u32string a = from_utf8(text), c = a;
    reverse_asm(&a[0], a.size());
    reverse_cpp(&c[0], c.size());
    std::cout << "  исходная : \"" << text << "\"\n"
              << "  ASM      : \"" << to_utf8(a) << "\"\n"
              << "  C++      : \"" << to_utf8(c) << "\"\n"
              << "  совпадают: " << (a == c ? "да" : "НЕТ") << "\n\n";
}

static int run_tests()
{
    int failed = 0;
    const char* cases[][2] = {
        {"", ""},
        {"A", "A"},
        {"ab", "ba"},
        {"abc", "cba"},
        {"Hello, World!", "!dlroW ,olleH"},
        {"АС-66", "66-СА"},
        {"шалаш", "шалаш"},
        {"Осовец Арсений", "йинесрА цевосО"},
        {"  пробелы  ", "  ылеборп  "},
    };
    for (auto& c : cases) {
        std::u32string a = from_utf8(c[0]), b = a;
        reverse_asm(&a[0], a.size());
        reverse_cpp(&b[0], b.size());
        bool ok = to_utf8(a) == c[1] && to_utf8(b) == c[1];
        std::cout << (ok ? "  [OK]   " : "  [FAIL] ") << '"' << c[0] << "\" -> \"" << to_utf8(a) << "\"\n";
        failed += !ok;
    }
    std::mt19937 rng(66);
    int lenFailed = 0;
    for (std::size_t n = 0; n <= 2000; ++n) {
        std::vector<char32_t> buf(n + 2), ref;
        buf.front() = buf.back() = 0xDEAD;
        for (std::size_t i = 1; i <= n; ++i)
            buf[i] = 0x20 + rng() % 0x500;
        ref.assign(buf.begin() + 1, buf.end() - 1);
        std::reverse(ref.begin(), ref.end());
        std::vector<char32_t> b2 = buf;
        reverse_asm(buf.data() + 1, n);
        reverse_cpp(b2.data() + 1, n);
        bool ok = std::equal(ref.begin(), ref.end(), buf.begin() + 1) &&
                  std::equal(ref.begin(), ref.end(), b2.begin() + 1) &&
                  buf.front() == 0xDEAD && buf.back() == 0xDEAD &&
                  b2.front() == 0xDEAD && b2.back() == 0xDEAD;
        lenFailed += !ok;
    }
    std::cout << "  длины 0..2000, сравнение с std::reverse и проверка границ: "
              << (lenFailed ? "ОШИБКИ: " + std::to_string(lenFailed) : std::string("OK")) << "\n";
    failed += lenFailed;
    std::cout << (failed ? "\nЕсть ошибки!\n" : "\nВсе тесты пройдены.\n");
    return failed ? 1 : 0;
}

using Fn = void (*)(char32_t*, std::size_t);

NOINLINE void reverse_std(char32_t* s, std::size_t n)
{
    std::reverse(s, s + n);
}

static double measure(Fn volatile fn, std::vector<char32_t>& buf, int reps)
{
    const int rounds = 9;
    std::vector<double> t;
    for (int r = 0; r < rounds; ++r) {
        auto t0 = std::chrono::steady_clock::now();
        for (int i = 0; i < reps; ++i)
            fn(buf.data(), buf.size());
        auto t1 = std::chrono::steady_clock::now();
        t.push_back(std::chrono::duration<double, std::nano>(t1 - t0).count() / reps);
    }
    std::sort(t.begin(), t.end());
    return t[rounds / 2];
}

static void run_bench()
{
#if defined(__aarch64__)
    const char* arch = "ARM64";
#else
    const char* arch = "IA-32";
#endif
#if defined(__clang__)
    std::cout << "  архитектура: " << arch << ", компилятор: clang " << __clang_version__ << "\n";
#elif defined(_MSC_VER)
    std::cout << "  архитектура: " << arch << ", компилятор: MSVC " << _MSC_VER << "\n";
#endif
    std::cout << "\n    символов   повторов      ASM, нс      C++, нс std::reverse, нс   C++/ASM\n";
    const std::size_t sizes[] = {16, 256, 4096, 65536, 1048576};
    std::mt19937 rng(7);
    for (std::size_t n : sizes) {
        std::vector<char32_t> a(n);
        for (auto& ch : a)
            ch = U'а' + rng() % 32;
        std::vector<char32_t> b = a, c = a;
        int reps = static_cast<int>(std::max<std::size_t>(20, 20000000 / (n + 64)));
        reverse_asm(a.data(), n);
        reverse_cpp(b.data(), n);
        reverse_std(c.data(), n);
        double tAsm = measure(reverse_asm, a, reps);
        double tCpp = measure(reverse_cpp, b, reps);
        double tStd = measure(reverse_std, c, reps);
        std::printf("  %10zu %10d %12.1f %12.1f %16.1f %9.2f\n", n, reps, tAsm, tCpp, tStd, tCpp / tAsm);
    }
    std::cout << "\n  C++/ASM > 1 - быстрее ассемблерная вставка, < 1 - быстрее C++.\n";
}

int main(int argc, char** argv)
{
#if defined(_WIN32)
    std::system("chcp 65001 > nul");
#endif
    std::string mode = argc > 1 ? argv[1] : "";
    std::cout << "Лабораторная работа 1. Вариант 1: перевернуть строку\n"
              << "Осовец А.О., группа АС-66\n\n";

    if (mode == "--demo") {
        show("Hello, World!");
        show("Брестский государственный технический университет");
        show("АПО ЭВМиС 2026");
        return 0;
    }
    if (mode == "--test")
        return run_tests();
    if (mode == "--bench") {
        run_bench();
        return 0;
    }

    std::cout << "Введите строку: ";
    std::string line;
    std::getline(std::cin, line);
    std::cout << '\n';
    show(line);
    return 0;
}
