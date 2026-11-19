#include "remove_spaces.h"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <random>
#include <string>
#include <vector>

using Function = std::size_t (*)(char*, std::size_t);

bool check(Function function, const std::string& input, const std::string& expected,
           const std::string& label) {
    // Контрольные байты обнаруживают запись за пределами переданного диапазона.
    std::vector<char> buffer(input.size() + 2, static_cast<char>(0x5a));
    std::copy(input.begin(), input.end(), buffer.begin() + 1);
    const std::size_t size = function(buffer.data() + 1, input.size());
    if (size != expected.size() || buffer.front() != static_cast<char>(0x5a) ||
        buffer.back() != static_cast<char>(0x5a) ||
        !std::equal(expected.begin(), expected.end(), buffer.begin() + 1)) {
        std::cerr << "FAIL: " << label << '\n';
        return false;
    }
    return true;
}

int main() {
    struct Case { const char* name; std::string input; std::string expected; };
    const std::vector<Case> cases = {
        {"one space", "a b", "ab"},
        {"empty", "", ""},
        {"spaces only", "     ", ""},
        {"no spaces", "abc", "abc"},
        {"repeated and edge spaces", "  a  b  ", "ab"},
        {"UTF-8 Russian", "  Привет  мир!  ", "Приветмир!"},
        {"tab is not space", " a\tb ", "a\tb"},
        {"nonbreaking space", " a\u00a0b ", "a\u00a0b"},
        {"embedded NUL", std::string("a\0 b", 4), std::string("a\0b", 3)},
        {"all ASCII bytes", [] { std::string s; for (int i = 0; i < 128; ++i) s += static_cast<char>(i); return s; }(),
         [] { std::string s; for (int i = 0; i < 128; ++i) if (i != 0x20) s += static_cast<char>(i); return s; }()},
        {"long line", std::string(65536, ' ') + std::string(65536, 'x'), std::string(65536, 'x')},
    };
    const struct { const char* name; Function function; } variants[] = {
        {"first expansion", remove_spaces}, {"second expansion", remove_spaces_second}
    };
    for (const auto& variant : variants) {
        if (variant.function(nullptr, 0) != 0) {
            std::cerr << "FAIL: " << variant.name << ": null with zero length\n";
            return 1;
        }
        std::cout << "PASS " << variant.name << ": null with zero length\n";
        for (const auto& test : cases) {
            if (!check(variant.function, test.input, test.expected, test.name)) return 1;
            std::cout << "PASS " << variant.name << ": " << test.name << '\n';
        }
        std::mt19937 rng(20261029);
        for (int i = 0; i < 5000; ++i) {
            std::string input;
            const auto length = rng() % 513;
            for (std::uint32_t j = 0; j < length; ++j) {
                input += static_cast<char>(rng() % 256);
            }
            std::string expected;
            for (const char ch : input) if (ch != ' ') expected += ch;
            if (!check(variant.function, input, expected, "random bytes")) return 1;
        }
        std::cout << "PASS " << variant.name << ": 5000 random byte sequences\n";
    }
    std::cout << "All assembly tests passed.\n";
}
