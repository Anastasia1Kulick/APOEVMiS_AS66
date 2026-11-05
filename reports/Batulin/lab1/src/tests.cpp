#include "combine.h"
#include <cstring>
#include <iostream>
#include <random>
#include <string>
#include <vector>

// Detects concatenating whole strings, taking the wrong half, rounding up,
// dropping spaces, writing beyond the terminator, or changing either input.
int RunTests() {
    struct Example { const char* first; const char* second; const char* expected; };
    const Example examples[] = {
        {"ABCDEFGH", "12345678", "ABCD1234"},
        {"abcde", "1234567", "ab123"},
        {"", "", ""},
        {"", "abcd", "ab"},
        {"abcd", "", "ab"},
        {"x", "y", ""},
        {"a b c d!", "12 34 56", "a b 12 3"},
        {"AB", "1234567890", "A12345"}
    };
    int passed = 0;
    const auto check = [&](const std::string& first, const std::string& second,
                           const std::string& expected) {
        const auto savedFirst = first, savedSecond = second;
        for (auto fn : {CombineCpp, CombineAsm}) {
            std::vector<char> out(expected.size() + 2, '#');
            fn(first.c_str(), first.size() / 2, second.c_str(), second.size() / 2, out.data());
            if (std::memcmp(out.data(), expected.c_str(), expected.size() + 1) != 0 ||
                out.back() != '#' || first != savedFirst || second != savedSecond) {
                std::cerr << "FAIL: first=[" << first << "] second=[" << second
                          << "] expected=[" << expected << "] actual=[" << out.data() << "]\n";
                return false;
            }
        }
        return true;
    };
    for (const auto& ex : examples) {
        if (!check(ex.first, ex.second, ex.expected)) return 1;
        ++passed;
    }
    std::mt19937 random(5);
    for (int n = 0; n < 300; ++n) {
        std::string first(random() % 257, ' '), second(random() % 257, ' ');
        for (auto& c : first) c = static_cast<char>(32 + random() % 95);
        for (auto& c : second) c = static_cast<char>(32 + random() % 95);
        const auto expected = first.substr(0, first.size() / 2) + second.substr(0, second.size() / 2);
        if (!check(first, second, expected)) return 1;
        ++passed;
    }
    std::cout << "PASS: " << passed << " cases, both C++ and x86 ASM.\n"
              << "Checked: empty/odd/unequal lengths, spaces, terminator, guard, unchanged inputs.\n";
    return 0;
}

#ifdef LAB_TEST_MAIN
int main() { return RunTests(); }
#endif
