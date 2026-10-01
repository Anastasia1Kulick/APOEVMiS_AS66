#pragma once

#include <cstddef>

constexpr std::size_t kStringCapacity = 256;

struct FourStrings {
    char line[4][kStringCapacity]{};
};

__declspec(noinline) void swap_cpp(FourStrings& strings);
__declspec(noinline) void swap_asm(FourStrings& strings);
