#pragma once
#include <cstddef>
extern "C" int check_condition(const char32_t* text, std::size_t n);
extern "C" void transform_text(char32_t* text, std::size_t n);
