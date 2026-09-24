#include "transform.h"
#include "utf8.h"
#include <algorithm>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <random>
#include <vector>
#ifdef _WIN32
#define NOMINMAX
#include <windows.h>
#endif

using Transform = void (*)(char32_t*, std::size_t);

void require(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}

void show(const std::string& input) {
    const auto original = decode_utf8(input);
    auto cpp = original, assembly = original;
    replace_cpp(cpp.data(), cpp.size());
    replace_asm(assembly.data(), assembly.size());
    require(cpp == assembly, "Implementations disagree");
    std::cout << "Input: [" << input << "]\n"
              << "C++:   [" << encode_utf8(cpp) << "]\n"
              << "ASM:   [" << encode_utf8(assembly) << "]\n"
              << "Match: YES\n\n";
}

void tests() {
    const std::vector<std::pair<std::u32string, std::u32string>> cases = {
        {U"", U""}, {U"a", U"+"}, {U"ab", U"+b"},
        {U"abc", U"+b+"}, {U"abcdef", U"+b+d+f"},
        {U"abcde", U"+b+d+"}, {U"a b c", U"+ + +"},
        {U"++++", U"++++"}, {U"Привет", U"+р+в+т"},
        {U"A🙂Б🚀", U"+🙂+🚀"}, {U"\t\n\t", U"+\n+"}
    };
    for (const auto& item : cases) {
        require(decode_utf8(encode_utf8(item.first)) == item.first,
                "UTF-8 round trip failed");
        for (Transform fn : {replace_cpp, replace_asm}) {
            std::vector<char32_t> buffer(item.first.size() + 2, U'@');
            std::copy(item.first.begin(), item.first.end(), buffer.begin() + 1);
            fn(buffer.data() + 1, item.first.size());
            require(buffer.front() == U'@' && buffer.back() == U'@',
                    "Function wrote outside its buffer");
            require(std::equal(item.second.begin(), item.second.end(),
                               buffer.begin() + 1), "Known-answer test failed");
        }
    }
    // Independently check each position, including zero and long lengths.
    std::mt19937 rng(606);
    for (std::size_t n = 0; n <= 1024; ++n) {
        std::u32string input(n, U' ');
        for (auto& c : input) c = static_cast<char32_t>(32 + rng() % 95);
        for (Transform fn : {replace_cpp, replace_asm}) {
            auto output = input;
            fn(output.data(), output.size());
            require(output.c_str()[n] == U'\0', "Terminator modified");
            for (std::size_t i = 0; i < n; ++i)
                require(output[i] == (i % 2 == 0 ? U'+' : input[i]),
                        "Position invariant failed");
        }
    }
    const std::vector<std::string> bad = {
        std::string("\xc0\xaf", 2), std::string("\x80", 1),
        std::string("\xe2\x82", 2), std::string("\xed\xa0\x80", 3),
        std::string("\xf4\x90\x80\x80", 4)
    };
    for (const auto& s : bad) {
        bool rejected = false;
        try { (void)decode_utf8(s); }
        catch (const std::runtime_error&) { rejected = true; }
        require(rejected, "Invalid UTF-8 accepted");
    }
    std::cout << "PASS: 11 known-answer cases (both functions, boundary guards)\n"
              << "PASS: 1025 lengths (both functions, position invariants)\n"
              << "PASS: UTF-8 round trips and 5 invalid inputs\n";
}

// Volatile dispatch plus separate translation units keep calls observable.
// No console output, copying, allocation or encoding inside the timed region.
double measure(Transform fn, const std::u32string& input, std::size_t repeats) {
    auto data = input;
    fn(data.data(), data.size()); // warm up
    data = input;
    Transform volatile dispatch = fn;
    const auto start = std::chrono::steady_clock::now();
    for (std::size_t i = 0; i < repeats; ++i)
        dispatch(data.data(), data.size());
    const auto end = std::chrono::steady_clock::now();
    for (std::size_t i = 0; i < data.size(); ++i)
        require(data[i] == (i % 2 == 0 ? U'+' : input[i]),
                "Benchmark result incorrect");
    return std::chrono::duration<double, std::nano>(end - start).count()
           / static_cast<double>(repeats);
}

void benchmark() {
    std::cout << "Benchmark: 7 rounds, median, warm buffer, repeated in-place calls\n"
              << "Ratio = C++ / ASM; greater than 1 means ASM is faster\n"
              << "length,repeats,cpp_ns_per_call,asm_ns_per_call,cpp_div_asm\n";
    for (std::size_t n : {16u, 256u, 4096u, 65536u}) {
        std::u32string input(n, U'a');
        for (std::size_t i = 0; i < n; ++i) input[i] = U'a' + i % 26;
        const auto repeats = std::max<std::size_t>(1000,
            std::min<std::size_t>(2000000, 160000000 / n));
        std::vector<double> cpp, assembly;
        for (int round = 0; round < 7; ++round) {
            // Alternate order to reduce systematic order bias.
            if (round % 2 == 0) {
                cpp.push_back(measure(replace_cpp, input, repeats));
                assembly.push_back(measure(replace_asm, input, repeats));
            } else {
                assembly.push_back(measure(replace_asm, input, repeats));
                cpp.push_back(measure(replace_cpp, input, repeats));
            }
        }
        std::sort(cpp.begin(), cpp.end());
        std::sort(assembly.begin(), assembly.end());
        std::cout << n << ',' << repeats << ',' << std::fixed
                  << std::setprecision(3) << cpp[3] << ',' << assembly[3]
                  << ',' << cpp[3] / assembly[3] << '\n';
    }
}

int main(int argc, char** argv) {
#ifdef _WIN32
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
#endif
    try {
        std::cout << "Lab 1 | Variant 6 | Replace positions 1, 3, 5, ... with +\n"
                  << "Backend: " << assembly_backend() << '\n';
#ifdef __clang__
        std::cout << "Compiler: Clang " << __clang_version__ << '\n';
#elif defined(_MSC_VER)
        std::cout << "Compiler: MSVC " << _MSC_VER << '\n';
#endif
        const std::string mode = argc > 1 ? argv[1] : "";
        if (mode == "--test") tests();
        else if (mode == "--bench") benchmark();
        else if (mode == "--demo") {
            for (const auto& s : {"abcdef", "abcde", "Привет", "a b c", ""})
                show(s);
        } else if (mode.empty()) {
            std::cout << "Enter a UTF-8 string (spaces allowed):\n";
            std::string input;
            if (!std::getline(std::cin, input))
                throw std::runtime_error("No input received");
            show(input);
        } else {
            std::cerr << "Usage: lab1 [--demo | --test | --bench]\n";
            return 2;
        }
    } catch (const std::exception& error) {
        std::cerr << "Error: " << error.what() << '\n';
        return 1;
    }
}
