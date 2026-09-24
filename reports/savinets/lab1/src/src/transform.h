#pragma once
#include <cstddef>

// Positions are counted from one; n is the number of Unicode code points.
// Both functions modify the buffer in place and do not touch its terminator.
void replace_cpp(char32_t* text, std::size_t n);
void replace_asm(char32_t* text, std::size_t n);
const char* assembly_backend();
