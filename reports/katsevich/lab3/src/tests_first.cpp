#include <cstddef>
#include <iostream>
#include <string>

// Возвращает новую длину; меняет только первые length байтов массива.
extern "C" std::size_t remove_spaces(char* data, std::size_t length);

int main() {
    std::string input = "a b";
    const std::size_t length = remove_spaces(input.data(), input.size());
    input.resize(length);
    if (input != "ab") {
        std::cerr << "FAIL: a b -> ab\n";
        return 1;
    }
    std::cout << "PASS: a b -> ab\n";
}
