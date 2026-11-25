#include <cmath>
#include <iostream>
#include <limits>

extern "C" double real(double, double);

int main() {
    struct Case { double x, y, expected; };
    const double tiny = std::numeric_limits<double>::denorm_min();
    const Case cases[] = {
        {9.0, std::ldexp(1.0, -52), 46.0},
        {-5.0, -std::ldexp(1.0, -53), 0.75},
        {9.0, tiny, 46.0}, {9.0, -tiny, 244.0}, {9.0, 0.0, 244.0},
        {-5.0, -tiny, 0.75}, {-5.0, tiny, 76.0}, {-5.0, 0.0, 76.0},
        {tiny, 9.0, 1.0}, {-tiny, 9.0, -161.0}, {0.0, 9.0, -161.0},
        {-tiny, -5.0, 3.0/29.0}, {tiny, -5.0, -49.0}, {0.0, -5.0, -49.0},
        {5.0, tiny, 76.0}, {5.0, -tiny, 76.0}, {5.0, 0.0, 76.0},
        {-9.0, tiny, 0.75}, {-9.0, -tiny, 0.75}, {-9.0, 0.0, 0.75},
        {tiny, 5.0, -49.0}, {-tiny, 5.0, -49.0}, {0.0, 5.0, -49.0},
        {tiny, -9.0, 3.0/85.0}, {-tiny, -9.0, 3.0/85.0}, {0.0, -9.0, 3.0/85.0},
    };
    int failed = 0;
    for (const auto& c : cases) {
        const double got = real(c.x, c.y);
        if (std::fabs(got-c.expected) > 1e-12) {
            std::cerr.precision(17);
            std::cerr << "FAIL real(" << c.x << ", " << c.y << "): " << got << " != " << c.expected << '\n';
            ++failed;
        }
    }
    if (failed) return 1;
    std::cout << "PASS exact-sum " << sizeof(cases)/sizeof(cases[0]) << " cases\n";
}
