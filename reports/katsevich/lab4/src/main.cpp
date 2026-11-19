#include <cerrno>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>

extern "C" double integer(int x, int y);
extern "C" double real(double x, double y);

// One complete numeric token per line: reject trailing garbage and extra tokens.
template <typename T>
bool read_value(const char* prompt, T& value) {
    std::cout << prompt << std::flush;
    std::string line;
    if (!std::getline(std::cin, line)) return false;
    std::istringstream input(line);
    if (!(input >> value)) return false;
    input >> std::ws;
    return input.eof();
}

// strtod may set ERANGE for a valid nonzero subnormal: keep that value.
// Reject only underflow all the way to zero; literal zero remains valid.
// The integer overload above retains its original strict parsing and range checks.
bool read_value(const char* prompt, double& value) {
    std::cout << prompt << std::flush;
    std::string line;
    if (!std::getline(std::cin, line)) return false;
    const char* start = line.c_str();
    char* end = nullptr;
    errno = 0;
    value = std::strtod(start, &end);
    if (end == start || (errno == ERANGE && value == 0.0)) return false;
    while (*end && std::isspace(static_cast<unsigned char>(*end))) ++end;
    // Checking against size also rejects an embedded NUL followed by extra data.
    return end == start + line.size();
}

int main() {
    std::cout << "mode (integer/real): " << std::flush;
    std::string mode;
    if (!std::getline(std::cin, mode) || (mode != "integer" && mode != "real")) {
        std::cerr << "error: mode must be integer or real\n";
        return 1;
    }
    double result;
    if (mode == "integer") {
        int x, y;
        if (!read_value("x: ", x) || !read_value("y: ", y) ||
            x < -1000 || x > 1000 || y < -1000 || y > 1000) {
            std::cerr << "error: x and y must be integers in [-1000, 1000]\n";
            return 1;
        }
        result = integer(x, y);
    } else {
        double x, y;
        if (!read_value("x: ", x) || !read_value("y: ", y) ||
            !std::isfinite(x) || !std::isfinite(y) ||
            std::fabs(x) > 1000 || std::fabs(y) > 1000) {
            std::cerr << "error: x and y must be finite real numbers in [-1000, 1000]\n";
            return 1;
        }
        result = real(x, y);
    }
    std::cout << "result = " << std::setprecision(std::numeric_limits<double>::max_digits10)
              << result << '\n';
}
