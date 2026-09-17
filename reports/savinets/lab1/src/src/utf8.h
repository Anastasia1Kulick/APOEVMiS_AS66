#pragma once
#include <cstdint>
#include <stdexcept>
#include <string>

// Encoding conversion is outside the functions being compared and timed.
inline std::u32string decode_utf8(const std::string& input) {
    std::u32string result;
    for (std::size_t i = 0; i < input.size();) {
        auto c = static_cast<unsigned char>(input[i++]);
        std::uint32_t cp;
        unsigned extra;
        std::uint32_t minimum;
        if (c < 0x80) { cp = c; extra = 0; minimum = 0; }
        else if (c >= 0xc2 && c <= 0xdf) {
            cp = c & 0x1f; extra = 1; minimum = 0x80;
        } else if (c >= 0xe0 && c <= 0xef) {
            cp = c & 0x0f; extra = 2; minimum = 0x800;
        } else if (c >= 0xf0 && c <= 0xf4) {
            cp = c & 7; extra = 3; minimum = 0x10000;
        } else { throw std::runtime_error("Invalid UTF-8 input"); }
        for (unsigned j = 0; j < extra; ++j) {
            if (i == input.size())
                throw std::runtime_error("Truncated UTF-8 input");
            c = static_cast<unsigned char>(input[i++]);
            if ((c & 0xc0) != 0x80)
                throw std::runtime_error("Invalid UTF-8 continuation");
            cp = (cp << 6) | (c & 0x3f);
        }
        if (cp < minimum || cp > 0x10ffff || (cp >= 0xd800 && cp <= 0xdfff))
            throw std::runtime_error("Invalid Unicode code point");
        result.push_back(static_cast<char32_t>(cp));
    }
    return result;
}

inline std::string encode_utf8(const std::u32string& input) {
    std::string result;
    for (std::uint32_t cp : input) {
        if (cp > 0x10ffff || (cp >= 0xd800 && cp <= 0xdfff))
            throw std::runtime_error("Invalid Unicode code point");
        if (cp < 0x80) result += static_cast<char>(cp);
        else if (cp < 0x800) {
            result += static_cast<char>(0xc0 | (cp >> 6));
            result += static_cast<char>(0x80 | (cp & 0x3f));
        } else if (cp < 0x10000) {
            result += static_cast<char>(0xe0 | (cp >> 12));
            result += static_cast<char>(0x80 | ((cp >> 6) & 0x3f));
            result += static_cast<char>(0x80 | (cp & 0x3f));
        } else {
            result += static_cast<char>(0xf0 | (cp >> 18));
            result += static_cast<char>(0x80 | ((cp >> 12) & 0x3f));
            result += static_cast<char>(0x80 | ((cp >> 6) & 0x3f));
            result += static_cast<char>(0x80 | (cp & 0x3f));
        }
    }
    return result;
}
