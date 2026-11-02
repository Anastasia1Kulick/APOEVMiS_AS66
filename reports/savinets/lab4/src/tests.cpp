#include <algorithm>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <limits>
#include <random>
#include <utility>
#include <vector>

extern "C" double integer(int, int);
#ifndef INTEGER_ONLY
extern "C" double real(double, double);
#endif

// Error-free TwoSum recovers the part discarded when x+y rounds to double.
// Python Fraction tests provide an independent exact-rational branch oracle.
static int sum_side(double x, double y, double boundary) {
    const double s = x + y;
    if (s > boundary) return 1;
    if (s < boundary) return -1;
    const double bv = s - x;
    const double av = s - bv;
    const double error = (x - av) + (y - bv);
    return (error > 0) - (error < 0);
}

static long double reference(double x, double y) {
    const long double a = x, b = y;
    if (sum_side(x, y, 9) > 0) return 5*a + 2*a*b + 1;
    if (sum_side(x, y, -5) < 0) return (2*a*b + 3)/(b*b + 4);
    return 3*a*a - 2*b*b + 1;
}

static bool check(const char* mode, double x, double y, double got, double expected) {
    if (std::isfinite(got) && std::fabs(got - expected) <= 3e-12 * std::max(1.0, std::fabs(expected))) return true;
    std::cerr.precision(17);
    std::cerr << mode << '(' << x << ',' << y << "): got " << got << ", expected " << expected << '\n';
    return false;
}

int main() {
    const std::vector<std::pair<int,int>> integers = {
        {-6,0}, {10,0}, {0,0}, {-5,0}, {9,0}, {-6,-1}, {5,5},
        {-3,-2}, {4,5}, {-1000,-1000}, {1000,1000}, {1000,-1000},
        {-3,4}, {3,-9}, {-999,1000}, {999,-1000}
    };
    int count = 0;
    for (auto [x,y] : integers) {
        if (!check("integer",x,y,integer(x,y),static_cast<double>(reference(x,y)))) return 1;
        ++count;
    }
    std::mt19937 gen(42);
    std::uniform_int_distribution<int> ints(-1000,1000);
    for (int i=0;i<10000;++i) {
        int x=ints(gen), y=ints(gen);
        if (!check("integer",x,y,integer(x,y),static_cast<double>(reference(x,y)))) return 1;
        ++count;
    }
#ifndef INTEGER_ONLY
    const std::vector<std::pair<double,double>> reals = {
        {-6,0}, {10,0}, {0,0}, {-5,0}, {9,0}, {-6,-1}, {5,5},
        {-2.5,-2.5}, {4.5,4.5}, {-8.25,1.5}, {5.5,4.25}, {-1.25,2.75},
        {-1000,-1000}, {1000,1000}, {1000,-1000},
        {std::nextafter(-5.0,-INFINITY),0}, {std::nextafter(-5.0,INFINITY),0},
        {std::nextafter(9.0,-INFINITY),0}, {std::nextafter(9.0,INFINITY),0}
    };
    for (auto [x,y] : reals) {
        if (!check("real",x,y,real(x,y),static_cast<double>(reference(x,y)))) return 1;
        ++count;
    }
    std::uniform_real_distribution<double> values(-1000,1000);
    for (int i=0;i<10000;++i) {
        double x=values(gen), y=values(gen);
        if (!check("real",x,y,real(x,y),static_cast<double>(reference(x,y)))) return 1;
        ++count;
    }
#endif
    std::cout << "PASS " << count << " numerical cases\n";
}
