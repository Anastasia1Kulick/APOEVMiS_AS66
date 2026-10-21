#include "string_swap.h"

#include <utility>

static_assert(sizeof(FourStrings) == 4 * kStringCapacity,
              "The assembly offsets require four adjacent buffers.");

void swap_cpp(FourStrings& strings) {
    for (int index = 0; index < static_cast<int>(kStringCapacity); ++index) {
        std::swap(strings.line[0][index], strings.line[2][index]);
        std::swap(strings.line[1][index], strings.line[3][index]);
    }
}

void swap_asm(FourStrings& strings) {
    FourStrings* data = &strings;
    __asm {
        mov esi, data
        xor edx, edx
        mov ecx, 256
    swap_next_byte:
        // Exchange the corresponding bytes of strings 1 and 3.
        mov al, byte ptr [esi + edx]
        mov ah, byte ptr [esi + edx + 512]
        mov byte ptr [esi + edx], ah
        mov byte ptr [esi + edx + 512], al

        // Exchange the corresponding bytes of strings 2 and 4.
        mov al, byte ptr [esi + edx + 256]
        mov ah, byte ptr [esi + edx + 768]
        mov byte ptr [esi + edx + 256], ah
        mov byte ptr [esi + edx + 768], al

        inc edx
        loop swap_next_byte
    }
}
