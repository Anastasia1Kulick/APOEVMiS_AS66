#include "transform.h"

static_assert(sizeof(char32_t) == 4, "A character must occupy four bytes");

#if defined(_MSC_VER)
#define NOINLINE __declspec(noinline)
#else
#define NOINLINE __attribute__((noinline))
#endif

NOINLINE void replace_cpp(char32_t* text, std::size_t n) {
    // Positions 1, 3, 5 correspond to indices 0, 2, 4.
    for (std::size_t i = 0, count = n / 2 + n % 2; i < count; ++i)
        text[i * 2] = U'+';
}

NOINLINE void replace_asm(char32_t* text, std::size_t n) {
    // Avoid n + 1: that expression could overflow for the largest size_t.
    std::size_t count = n / 2 + n % 2;
#if defined(_MSC_VER) && defined(_M_IX86)
    // Main course implementation: Intel x86, MS Visual Studio, Win32.
    // EAX = current address, ECX = remaining replacements, EDX = U'+'.
    __asm {
        mov eax, text
        mov ecx, count
        test ecx, ecx
        jz finished
        mov edx, 43
    next_character:
        mov dword ptr [eax], edx
        add eax, 8
        dec ecx
        jnz next_character
    finished:
    }
#elif defined(__aarch64__) && defined(__clang__)
    // Mac Apple Silicon adaptation. This is ARM64, not Intel assembly.
    asm volatile(
        "cbz %[count], 2f\n"
        "mov w9, #43\n"
        "1:\n"
        "str w9, [%[text]]\n"
        "add %[text], %[text], #8\n"
        "subs %[count], %[count], #1\n"
        "b.ne 1b\n"
        "2:\n"
        : [text] "+&r"(text), [count] "+&r"(count)
        :
        : "x9", "cc", "memory");
#elif defined(__x86_64__) && (defined(__clang__) || defined(__GNUC__))
    // Optional Intel x86-64 build on macOS/Linux (GNU assembler syntax).
    asm volatile(
        "testq %[count], %[count]\n"
        "jz 2f\n"
        "1:\n"
        "movl $43, (%[text])\n"
        "addq $8, %[text]\n"
        "decq %[count]\n"
        "jnz 1b\n"
        "2:\n"
        : [text] "+&r"(text), [count] "+&r"(count)
        :
        : "cc", "memory");
#else
#error Unsupported target. Use MSVC Win32 (x86) or Clang on macOS.
#endif
}

const char* assembly_backend() {
#if defined(_MSC_VER) && defined(_M_IX86)
    return "Intel x86 / MSVC inline __asm";
#elif defined(__aarch64__)
    return "ARM64 / Apple Silicon (Mac adaptation)";
#else
    return "Intel x86-64 / GNU-style inline asm";
#endif
}
