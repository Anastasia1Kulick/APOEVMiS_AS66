// lab4_main.cpp
// Лаб. №1 (сопроцессор). Раздел 1 (целочисленные команды) +
// Раздел 2 (вещественные команды). Вариант 1.
//
// y = 6xy - 4y,                          x + y > 9
//   = (2xy + 3 + x) / (x^2 + 3y^2 + 1),  x + y < -1
//   = 3x^2 - 2y + 6,                     -1 <= x + y <= 9

#include <cstdio>
#include <windows.h>

extern "C" double ComputeIntAsm(int x, int y);             // реализация в lab4_int.asm
extern "C" double ComputeRealAsm(double x, double y);       // реализация в lab4_real.asm

int main()
{
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);

    printf("=== Раздел 1: целочисленные команды сопроцессора ===\n");
    printf("Введите целые x и y через пробел: ");
    int xi, yi;
    scanf_s("%d %d", &xi, &yi);
    double resultInt = ComputeIntAsm(xi, yi);
    printf("y = %.6f   (x=%d, y=%d, x+y=%d)\n\n", resultInt, xi, yi, xi + yi);

    printf("=== Раздел 2: вещественные команды сопроцессора ===\n");
    printf("Введите вещественные x и y через пробел: ");
    double xr, yr;
    scanf_s("%lf %lf", &xr, &yr);
    double resultReal = ComputeRealAsm(xr, yr);
    printf("y = %.6f   (x=%.3f, y=%.3f, x+y=%.3f)\n", resultReal, xr, yr, xr + yr);

    return 0;
}