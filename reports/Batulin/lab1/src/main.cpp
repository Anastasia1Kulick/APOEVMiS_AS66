#include "combine.h"
#include <Windows.h>
#include <intrin.h>
#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <iomanip>
#include <iostream>
#include <limits>
#include <string>
#include <vector>

int RunTests();
using Combine = void (*)(const char*, std::size_t, const char*, std::size_t, char*);

bool ShowResult(const std::string& first, const std::string& second) {
    const auto n1 = first.size() / 2, n2 = second.size() / 2;
    std::vector<char> cpp(n1 + n2 + 1), assembly(n1 + n2 + 1);
    CombineCpp(first.c_str(), n1, second.c_str(), n2, cpp.data());
    CombineAsm(first.c_str(), n1, second.c_str(), n2, assembly.data());
    const bool same = cpp == assembly;
    std::cout << "String 1: [" << first << "]  length=" << first.size() << ", half=" << n1
              << "\nString 2: [" << second << "]  length=" << second.size() << ", half=" << n2
              << "\nC++:      [" << cpp.data() << "]\nASM:      [" << assembly.data() << "]\n"
              << (same ? "MATCH" : "ERROR: results differ") << "\n\n";
    return same;
}

double Measure(Combine fn, const std::string& first, const std::string& second,
               std::vector<char>& out, std::size_t iterations, volatile std::uint64_t& checksum) {
    const auto n1 = first.size() / 2, n2 = second.size() / 2;
    const auto start = std::chrono::steady_clock::now();
    for (std::size_t i = 0; i < iterations; ++i) {
        fn(first.c_str(), n1, second.c_str(), n2, out.data());
        checksum += static_cast<unsigned char>(out[i % (n1 + n2)]);
    }
    const auto stop = std::chrono::steady_clock::now();
    return std::chrono::duration<double, std::nano>(stop - start).count() / iterations;
}

int Benchmark() {
    if (RunTests() != 0) return 1;
    char cpu[49]{};
    int regs[4]{};
    __cpuid(regs, static_cast<int>(0x80000000u));
    if (static_cast<unsigned>(regs[0]) >= 0x80000004u) {
        for (int i = 0; i < 3; ++i) {
            __cpuid(regs, static_cast<int>(0x80000002u + i));
            std::memcpy(cpu + 16 * i, regs, 16);
        }
    }
    std::cout << "\nCPU: " << cpu << "\nMSVC " << _MSC_VER << ", Win32/x86";
#ifdef NDEBUG
    std::cout << ", Release /O2\n";
#else
    std::cout << ", Debug (use Release for timing)\n";
#endif
    std::cout << "Median of 9 batches; alternating C++/ASM order; 1000 warmups.\n"
              << "Input generation, length calculation and allocation are outside timing.\n"
              << "Equal input lengths; result bytes = length of one input.\n\n"
              << " Bytes/input    Calls/batch     C++ ns/call     ASM ns/call    C++/ASM\n";
    volatile std::uint64_t checksum = 0;
    const std::array<std::size_t, 4> lengths{8, 64, 1024, 16384};
    const std::array<std::size_t, 4> counts{200000, 100000, 20000, 2000};
    for (std::size_t row = 0; row < lengths.size(); ++row) {
        std::string first(lengths[row], 'A'), second(lengths[row], 'z');
        std::vector<char> out(lengths[row] + 1);
        for (int i = 0; i < 1000; ++i) {
            CombineCpp(first.c_str(), first.size() / 2, second.c_str(), second.size() / 2, out.data());
            CombineAsm(first.c_str(), first.size() / 2, second.c_str(), second.size() / 2, out.data());
        }
        std::array<double, 9> cpp{}, assembly{};
        for (std::size_t round = 0; round < cpp.size(); ++round) {
            if (round % 2 == 0) {
                cpp[round] = Measure(CombineCpp, first, second, out, counts[row], checksum);
                assembly[round] = Measure(CombineAsm, first, second, out, counts[row], checksum);
            } else {
                assembly[round] = Measure(CombineAsm, first, second, out, counts[row], checksum);
                cpp[round] = Measure(CombineCpp, first, second, out, counts[row], checksum);
            }
        }
        std::sort(cpp.begin(), cpp.end());
        std::sort(assembly.begin(), assembly.end());
        std::cout << std::setw(12) << lengths[row] << std::setw(15) << counts[row]
                  << std::fixed << std::setprecision(2) << std::setw(16) << cpp[4]
                  << std::setw(16) << assembly[4] << std::setw(12) << cpp[4] / assembly[4] << '\n';
    }
    std::cout << "\nChecksum: " << checksum << "\n"
              << "Ratio > 1: ASM is faster; ratio < 1: C++ is faster in this run.\n"
              << "Times include call/loop/checksum overhead and depend on CPU and system load.\n";
    return 0;
}

int main(int argc, char* argv[]) {
    // Windows-1251 uses one byte per Russian/English character.
    // This is a byte-string exercise; UTF-8 input is not supported.
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);
    std::cout << "LAB 1 | VARIANT 5 | Batulin Mikhail | AS-66\n"
              << "Join the first halves of two strings (floor(length / 2)).\n\n";
    const std::string mode = argc > 1 ? argv[1] : "";
    int result = 0;
    if (mode == "--test") result = RunTests();
    else if (mode == "--benchmark") result = Benchmark();
    else if (mode == "--demo") {
        if (!ShowResult("ABCDEFGH", "12345678") ||
            !ShowResult("abcde", "1234567") || !ShowResult("", "abcd")) result = 1;
        if (result == 0) result = RunTests();
    } else if (!mode.empty()) {
        std::cerr << "Usage: Lab1Variant5.exe [--demo|--test|--benchmark] [--hold]\n";
        result = 2;
    } else {
        std::string first, second;
        std::cout << "Input encoding: Windows-1251. Spaces are preserved.\nString 1: ";
        if (!std::getline(std::cin, first)) return 1;
        std::cout << "String 2: ";
        if (!std::getline(std::cin, second)) return 1;
        if (first.size() > static_cast<std::size_t>((std::numeric_limits<int>::max)()) ||
            second.size() > static_cast<std::size_t>((std::numeric_limits<int>::max)())) return 1;
        std::cout << '\n';
        result = ShowResult(first, second) ? 0 : 1;
        if (result == 0) result = Benchmark();
    }
    if (argc > 2 && std::string(argv[2]) == "--hold") {
        std::cout << "\nPress Enter to close." << std::flush;
        std::cin.get();
    }
    return result;
}
