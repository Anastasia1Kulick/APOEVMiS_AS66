#include "string_swap.h"

#include <algorithm>
#include <chrono>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

namespace {

constexpr int kIterations = 200000;
constexpr int kTrials = 5;
volatile unsigned int g_observed_byte = 0;

bool read_four_strings(FourStrings& result) {
    for (int index = 0; index < 4; ++index) {
        for (;;) {
            std::cout << "Enter string " << index + 1 << " (up to 255 bytes): ";
            std::string input;
            if (!std::getline(std::cin, input)) {
                return false;
            }
            if (input.size() >= kStringCapacity) {
                std::cout << "Too long. Please enter this string again.\n";
                continue;
            }
            std::memcpy(result.line[index], input.c_str(), input.size() + 1);
            break;
        }
    }
    return true;
}

void print_four_strings(const char* label, const FourStrings& strings) {
    std::cout << label << '\n';
    for (int index = 0; index < 4; ++index) {
        std::cout << "  " << index + 1 << ": [" << strings.line[index] << "]\n";
    }
}

double median_milliseconds(void (*operation)(FourStrings&),
                           const FourStrings& original) {
    using clock = std::chrono::steady_clock;
    std::vector<double> samples;
    samples.reserve(kTrials);

    for (int trial = 0; trial < kTrials; ++trial) {
        FourStrings working = original;
        operation(working); // Warm up the function before each measured series.
        working = original;

        const auto start = clock::now();
        for (int iteration = 0; iteration < kIterations; ++iteration) {
            operation(working);
        }
        const auto finish = clock::now();
        g_observed_byte += static_cast<unsigned char>(working.line[0][0]);
        samples.push_back(
            std::chrono::duration<double, std::milli>(finish - start).count());
    }

    std::sort(samples.begin(), samples.end());
    return samples[kTrials / 2];
}

} // namespace

int main() {
    FourStrings original;
    if (!read_four_strings(original)) {
        std::cerr << "Input ended before all four strings were entered.\n";
        return 1;
    }

    FourStrings cpp_result = original;
    FourStrings asm_result = original;
    swap_cpp(cpp_result);
    swap_asm(asm_result);

    print_four_strings("Original strings:", original);
    print_four_strings("After C++ function:", cpp_result);
    print_four_strings("After ASM function:", asm_result);

    if (std::memcmp(&cpp_result, &asm_result, sizeof(FourStrings)) != 0) {
        std::cerr << "ERROR: C++ and ASM results differ.\n";
        return 2;
    }
    std::cout << "Results match.\n";

    const double cpp_ms = median_milliseconds(swap_cpp, original);
    const double asm_ms = median_milliseconds(swap_asm, original);
    std::cout << std::fixed << std::setprecision(3);
    std::cout << "Release Win32 benchmark: " << kTrials << " trials, "
              << kIterations << " swaps per trial (median).\n";
    std::cout << "C++: " << cpp_ms << " ms\n";
    std::cout << "ASM: " << asm_ms << " ms\n";
    if (asm_ms > 0.0) {
        std::cout << "C++ / ASM time ratio: " << cpp_ms / asm_ms << '\n';
    }
    return 0;
}
