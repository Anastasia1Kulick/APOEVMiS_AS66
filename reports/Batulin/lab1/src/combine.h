#pragma once
#include <cstddef>

// Buffers must not overlap; out has at least firstCount + secondCount + 1 bytes.
void CombineCpp(const char* first, std::size_t firstCount,
                const char* second, std::size_t secondCount, char* out);
void CombineAsm(const char* first, std::size_t firstCount,
                const char* second, std::size_t secondCount, char* out);
