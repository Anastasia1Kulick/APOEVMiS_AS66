#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>

#include <chrono>
#include <cstddef>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error Select the Win32 platform in Microsoft Visual Studio.
#endif

__declspec(noinline) std::size_t ReplaceSpacesCpp(char* text) noexcept
{
    if (text == nullptr)
        return 0;

    std::size_t replacements = 0;
    while (*text != '\0') {
        if (*text == ' ') {
            *text = '\t';
            ++replacements;
        }
        ++text;
    }
    return replacements;
}

__declspec(noinline) std::size_t __cdecl ReplaceSpacesAsm(char* text) noexcept
{
    std::size_t replacements = 0;

    __asm {
        mov edx, text
        xor ecx, ecx
        test edx, edx
        jz finished

    scan_byte:
        mov al, byte ptr [edx]
        test al, al
        jz finished
        cmp al, 20h
        jne next_byte
        mov byte ptr [edx], 09h
        inc ecx

    next_byte:
        inc edx
        jmp scan_byte

    finished:
        mov replacements, ecx
    }

    return replacements;
}

std::string MakeBenchmarkString()
{
    std::string result;
    result.reserve(4096);
    for (std::size_t index = 0; index < 4096; ++index) {
        if (index % 5 == 4)
            result.push_back(' ');
        else
            result.push_back(static_cast<char>('A' + index % 26));
    }
    return result;
}

int main()
{
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);

    std::cout << "АПО ЭВМиС. Лабораторная работа 1\n"
                 "Ярома А. И. Вариант 12\n"
                 "Введите строку: ";

    std::string original;
    if (!std::getline(std::cin, original))
        return 1;

    std::string cppResult = original;
    std::string asmResult = original;
    const std::size_t cppCount = ReplaceSpacesCpp(cppResult.data());
    const std::size_t asmCount = ReplaceSpacesAsm(asmResult.data());

    std::cout << "\nИсходная строка: " << original
              << "\nРезультат C++:   " << cppResult
              << "\nРезультат ASM:   " << asmResult
              << "\nЗамен C++ / ASM: " << cppCount << " / " << asmCount
              << "\nРезультаты совпадают: "
              << (cppResult == asmResult ? "да" : "нет") << "\n";

    constexpr std::size_t runs = 1000;
    const std::string benchmarkString = MakeBenchmarkString();
    std::vector<std::string> cppData(runs, benchmarkString);
    std::vector<std::string> asmData(runs, benchmarkString);
    volatile std::size_t checksum = 0;

    const auto cppStart = std::chrono::steady_clock::now();
    for (std::string& value : cppData)
        checksum += ReplaceSpacesCpp(value.data());
    const auto cppFinish = std::chrono::steady_clock::now();

    const auto asmStart = std::chrono::steady_clock::now();
    for (std::string& value : asmData)
        checksum += ReplaceSpacesAsm(value.data());
    const auto asmFinish = std::chrono::steady_clock::now();

    const auto cppTime = std::chrono::duration<double, std::micro>(
        cppFinish - cppStart).count();
    const auto asmTime = std::chrono::duration<double, std::micro>(
        asmFinish - asmStart).count();

    std::cout << std::fixed << std::setprecision(2)
              << "\nСравнение быстродействия (" << runs
              << " строк по " << benchmarkString.size() << " символов):\n"
              << "C++: " << cppTime << " мкс\n"
              << "ASM: " << asmTime << " мкс\n"
              << "Контрольная сумма: " << checksum << '\n';

    return cppResult == asmResult && cppCount == asmCount ? 0 : 2;
}
