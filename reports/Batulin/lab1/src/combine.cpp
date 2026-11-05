#include "combine.h"

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error Build with MSVC for Win32 (x86): inline __asm is required.
#endif

__declspec(noinline) void CombineCpp(const char* first, std::size_t firstCount,
                                    const char* second, std::size_t secondCount, char* out) {
    for (std::size_t i = 0; i < firstCount; ++i) out[i] = first[i];
    for (std::size_t i = 0; i < secondCount; ++i) out[firstCount + i] = second[i];
    out[firstCount + secondCount] = '\0';
}

__declspec(noinline) void CombineAsm(const char* first, std::size_t firstCount,
                                    const char* second, std::size_t secondCount, char* destination) {
    __asm {
        cld                         // Forward copying; DF = 0.
        mov esi, first              // Source address for the first half.
        mov edi, destination        // Destination is advanced by MOVSB.
        mov ecx, firstCount
        rep movsb                   // Zero count also works for an empty half.
        mov esi, second
        mov ecx, secondCount
        rep movsb
        mov byte ptr [edi], 0        // C string terminator, excluded from lengths.
    }
}
