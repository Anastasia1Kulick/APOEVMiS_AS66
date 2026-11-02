#include "lab2.h"
#include <algorithm>
#include <stdexcept>
#include <string>
#include <array>
#include <iostream>
#include <sstream>
#include <random>

constexpr std::size_t MAX_TEXT = 100;
struct Input {
    std::array<char32_t, MAX_TEXT + 1> text{};
    std::size_t n = 0;
};

// Decode directly into a fixed buffer; no text-sized auxiliary buffer.
Input read_text(std::istream& in) {
    Input result;
    for (;;) {
        int first = in.get();
        if (first == EOF) throw std::runtime_error("Missing final period");
        if (first == '.') break;
        unsigned char c = static_cast<unsigned char>(first);
        unsigned extra = 0;
        char32_t cp = 0, minimum = 0;
        if (c < 0x80) cp = c;
        else if (c >= 0xC2 && c <= 0xDF) {
            cp = c & 31; extra = 1; minimum = 0x80;
        } else if (c >= 0xE0 && c <= 0xEF) {
            cp = c & 15; extra = 2; minimum = 0x800;
        } else if (c >= 0xF0 && c <= 0xF4) {
            cp = c & 7; extra = 3; minimum = 0x10000;
        } else throw std::runtime_error("Invalid UTF-8");
        for (unsigned j = 0; j < extra; ++j) {
            int next = in.get();
            if (next == EOF || (next & 0xC0) != 0x80)
                throw std::runtime_error("Invalid UTF-8 continuation");
            cp = (cp << 6) | (next & 63);
        }
        if (cp < minimum || cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF))
            throw std::runtime_error("Invalid Unicode code point");
        if (result.n == MAX_TEXT) throw std::runtime_error("More than 100 characters");
        result.text[result.n++] = cp;
    }
    if (!result.n) throw std::runtime_error("Empty text");
    return result;
}

void print_text(const Input& input) {
    // Fixed-size UTF-8 scratch for one character, not the entire text.
    for (std::size_t i = 0; i < input.n; ++i) {
        const auto cp = static_cast<unsigned>(input.text[i]);
        char b[4]; int n;
        if (cp < 0x80) { b[0] = static_cast<char>(cp); n = 1; }
        else if (cp < 0x800) {
            b[0] = static_cast<char>(0xC0 | (cp >> 6));
            b[1] = static_cast<char>(0x80 | (cp & 63)); n = 2;
        } else if (cp < 0x10000) {
            b[0] = static_cast<char>(0xE0 | (cp >> 12));
            b[1] = static_cast<char>(0x80 | ((cp >> 6) & 63));
            b[2] = static_cast<char>(0x80 | (cp & 63)); n = 3;
        } else {
            b[0] = static_cast<char>(0xF0 | (cp >> 18));
            b[1] = static_cast<char>(0x80 | ((cp >> 12) & 63));
            b[2] = static_cast<char>(0x80 | ((cp >> 6) & 63));
            b[3] = static_cast<char>(0x80 | (cp & 63)); n = 4;
        }
        std::cout.write(b, n);
    }
}

void run(std::istream& in) {
    std::cout << "Enter 1..100 characters, end with a period.\n"
              << "Condition: uppercase Latin count equals uppercase Russian count (including Yo).\n"
              << "If true: swap case of Latin letters.\n";
    auto input = read_text(in);
    std::cout << "Original: "; print_text(input); std::cout << '\n';
    const bool ok = check_condition(input.text.data(), input.n) != 0;
    std::cout << "Condition: " << (ok ? "TRUE" : "FALSE") << '\n';
    if (ok) transform_text(input.text.data(), input.n);
    else std::cout << "Transformation skipped.\n";
    std::cout << "Result: "; print_text(input); std::cout << '\n';
}

void require(bool ok) {
    if (!ok) throw std::runtime_error("Test failed");
}
void tests() {
    const std::pair<std::u32string, bool> cases[] = {
        {U"AaБб", true}, {U"ABАЯ", true}, {U"AЁ", true},
        {U"AБЁ", false}, {U"ABCА", false}, {U"abc", true},
        {U"123 !", true}, {U"Ё", false}, {U"ё", true},
        {U"AZazАЯЁаяё", false}, {U"@AZ[ `az{", false}
    };
    for (const auto& item : cases) {
        std::array<char32_t, 103> b{};
        b.front() = b.back() = U'@';
        std::copy(item.first.begin(), item.first.end(), b.begin() + 1);
        require((check_condition(b.data() + 1, item.first.size()) != 0) == item.second);
        transform_text(b.data() + 1, item.first.size());
        for (std::size_t i = 0; i < item.first.size(); ++i) {
            auto c = item.first[i];
            auto expected = c >= U'A' && c <= U'Z' ? c + 32 :
                            c >= U'a' && c <= U'z' ? c - 32 : c;
            require(b[i + 1] == expected);
        }
        require(b.front() == U'@' && b.back() == U'@');
    }
    std::mt19937 rng(206);
    for (std::size_t n = 0; n <= 100; ++n) {
        for (int round = 0; round < 50; ++round) {
            std::array<char32_t, 102> b{};
            b[0] = b[n + 1] = U'@';
            unsigned latin = 0, russian = 0;
            for (std::size_t i = 1; i <= n; ++i) {
                b[i] = static_cast<char32_t>(rng() % 0x500);
                latin += b[i] >= U'A' && b[i] <= U'Z';
                russian += (b[i] >= U'А' && b[i] <= U'Я') || b[i] == U'Ё';
            }
            require((check_condition(b.data() + 1, n) != 0) == (latin == russian));
            auto original = b;
            transform_text(b.data() + 1, n);
            for (std::size_t i = 1; i <= n; ++i) {
                auto c = original[i];
                require(b[i] == (c >= U'A' && c <= U'Z' ? c + 32 :
                                c >= U'a' && c <= U'z' ? c - 32 : c));
            }
            require(b[0] == U'@' && b[n + 1] == U'@');
        }
    }
    for (const auto& s : {".", "abc", "\x80.", "\xC0\xAF.", "\xED\xA0\x80.", "\xF4\x90\x80\x80."}) {
        std::istringstream in(s); bool rejected = false;
        try { (void)read_text(in); } catch (const std::runtime_error&) { rejected = true; }
        require(rejected);
    }
    std::istringstream limit(std::string(100, 'a') + ".");
    require(read_text(limit).n == 100);
    std::istringstream over(std::string(101, 'a') + ".");
    bool rejected = false;
    try { (void)read_text(over); } catch (const std::runtime_error&) { rejected = true; }
    require(rejected);
    std::istringstream stop("AБ.rest"); require(read_text(stop).n == 2);
    std::cout << "PASS: 11 known cases, including capital Yo and Latin boundaries\n"
              << "PASS: 5050 randomized cases, lengths 0..100, boundary guards\n"
              << "PASS: empty / missing period / invalid UTF-8 / 100 and 101 characters\n";
}

int main(int argc, char** argv) {
    try {
        std::cout << "Lab 2 | Variant 6\n";
        const std::string mode = argc > 1 ? argv[1] : "";
        if (mode == "--test") tests();
        else if (mode == "--demo") {
            for (const char* s : {"AaБб.", "ABCА.", "AЁ.", "abc 123.", "."}) {
                std::cout << "\nInput: " << s << '\n';
                std::istringstream in(s);
                try { run(in); } catch (const std::exception& e) {
                    std::cout << "Rejected: " << e.what() << '\n';
                }
            }
        } else if (mode.empty()) run(std::cin);
        else throw std::runtime_error("Usage: lab2 [--test | --demo]");
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << '\n'; return 1;
    }
}
