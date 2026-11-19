#pragma once
#include <cstddef>

// Удаляют из data[0..length) байты 0x20 на месте и возвращают новую длину.
// data может быть nullptr только при length == 0; NUL не записывается.
extern "C" std::size_t remove_spaces(char* data, std::size_t length);
extern "C" std::size_t remove_spaces_second(char* data, std::size_t length);
