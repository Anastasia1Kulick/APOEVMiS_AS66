#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <Windows.h>

#include <cstddef>
#include <cstdint>
#include <iostream>

#if !defined(_MSC_VER) || !defined(_M_IX86)
#error Build this project with MSVC for Win32.
#endif

extern "C" int __cdecl CheckConditionAsm(const std::uint32_t* text,
    std::size_t length, std::size_t* letters, std::size_t* digits);
extern "C" void __cdecl RotateLeftAsm(std::uint32_t* text, std::size_t length);

enum class InputStatus { Ok, Empty, TooLong, NoPeriod, InvalidUtf8 };

// Read one Unicode character without allocating a string or a second buffer.
bool ReadCharacter(std::istream& input, std::uint32_t& value)
{
    const int first = input.get();
    if (first == std::char_traits<char>::eof())
        return false;
    const auto byte = static_cast<unsigned char>(first);
    unsigned remaining = 0;
    std::uint32_t minimum = 0;
    if (byte < 0x80) {
        value = byte;
        return true;
    }
    if (byte >= 0xC2 && byte <= 0xDF) {
        value = byte & 0x1F; remaining = 1; minimum = 0x80;
    } else if (byte >= 0xE0 && byte <= 0xEF) {
        value = byte & 0x0F; remaining = 2; minimum = 0x800;
    } else if (byte >= 0xF0 && byte <= 0xF4) {
        value = byte & 0x07; remaining = 3; minimum = 0x10000;
    } else {
        return false;
    }
    while (remaining-- != 0) {
        const int next = input.get();
        if (next == std::char_traits<char>::eof() || (next & 0xC0) != 0x80)
            return false;
        value = (value << 6) | (next & 0x3F);
    }
    return value >= minimum && value <= 0x10FFFF
        && !(value >= 0xD800 && value <= 0xDFFF);
}

InputStatus ReadText(std::istream& input, std::uint32_t* text,
    std::size_t capacity, std::size_t& length)
{
    length = 0;
    bool overflow = false;
    for (;;) {
        if (input.peek() == std::char_traits<char>::eof())
            return InputStatus::NoPeriod;
        std::uint32_t character = 0;
        if (!ReadCharacter(input, character))
            return InputStatus::InvalidUtf8;
        if (character == '.') {
            text[length] = 0;
            if (overflow)
                return InputStatus::TooLong;
            return length == 0 ? InputStatus::Empty : InputStatus::Ok;
        }
        if (length < capacity)
            text[length++] = character;
        else
            overflow = true;
    }
}

void PrintText(const std::uint32_t* text, std::size_t length)
{
    for (std::size_t index = 0; index < length; ++index) {
        const std::uint32_t value = text[index];
        auto byte = [](std::uint32_t part) {
            std::cout.put(static_cast<char>(part));
        };
        if (value < 0x80) {
            byte(value);
        } else if (value < 0x800) {
            byte(0xC0 | (value >> 6)); byte(0x80 | (value & 0x3F));
        } else if (value < 0x10000) {
            byte(0xE0 | (value >> 12));
            byte(0x80 | ((value >> 6) & 0x3F)); byte(0x80 | (value & 0x3F));
        } else {
            byte(0xF0 | (value >> 18)); byte(0x80 | ((value >> 12) & 0x3F));
            byte(0x80 | ((value >> 6) & 0x3F)); byte(0x80 | (value & 0x3F));
        }
    }
}

int main()
{
    SetConsoleCP(CP_UTF8);
    SetConsoleOutputCP(CP_UTF8);
    constexpr std::size_t MaxLength = 100;
    std::uint32_t text[MaxLength + 1] = {};
    std::size_t length = 0;

    std::cout << "АПО ЭВМиС. Лабораторная работа №2\n"
                 "Ярома А. И. | АС-66 | Вариант 12\n"
                 "Условие: число строчных русских букв равно числу цифр.\n"
                 "Правило: циклический сдвиг на 3 символа влево.\n"
                 "Введите от 1 до 100 символов; завершите точкой и нажмите Enter:\n";

    const InputStatus status = ReadText(std::cin, text, MaxLength, length);
    if (status != InputStatus::Ok) {
        std::cout << "Последовательность не является допустимым текстом: ";
        switch (status) {
        case InputStatus::Empty: std::cout << "пустой текст.\n"; break;
        case InputStatus::TooLong: std::cout << "больше 100 символов.\n"; break;
        case InputStatus::NoPeriod: std::cout << "нет завершающей точки.\n"; break;
        default: std::cout << "ошибка кодировки UTF-8.\n"; break;
        }
        std::cout << "Преобразование не выполняется.\n";
        return 1;
    }

    std::cout << "\nИсходный текст: \"";
    PrintText(text, length);
    std::cout << "\"\nДлина: " << length << " символов\n";

    std::size_t letters = 0, digits = 0;
    const bool satisfied = CheckConditionAsm(text, length, &letters, &digits) != 0;
    std::cout << "Строчных русских букв: " << letters
              << "\nЦифр: " << digits << '\n';
    if (!satisfied) {
        std::cout << "Условие не выполнено. Текст не преобразуется.\n";
        return 0;
    }

    std::cout << "Условие выполнено. Сдвиг на 3 символа влево.\n";
    RotateLeftAsm(text, length);
    std::cout << "Результат: \"";
    PrintText(text, length);
    std::cout << "\"\n";
    return 0;
}
