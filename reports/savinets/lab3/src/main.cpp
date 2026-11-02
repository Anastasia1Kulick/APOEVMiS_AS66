#include "remove_spaces.h"

#include <iostream>
#include <string>

int main() {
    std::cout << "Введите строку: " << std::flush;
    std::string line;
    if (!std::getline(std::cin, line)) {
        return 0; // EOF до ввода строки
    }
    const std::size_t length = remove_spaces(line.data(), line.size());
    line.resize(length);
    std::cout << "Результат: " << line << '\n';
    return std::cout ? 0 : 1;
}
