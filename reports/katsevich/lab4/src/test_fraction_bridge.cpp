// Test-only persistent bridge: hexadecimal binary64 tokens preserve every input bit.
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <string>
extern "C" double real(double, double);
int main() {
    std::string sx, sy;
    while (std::cin >> sx >> sy) {
        double x = std::strtod(sx.c_str(), nullptr);
        double y = std::strtod(sy.c_str(), nullptr);
        std::cout << std::hexfloat << real(x, y) << '\n';
    }
}
