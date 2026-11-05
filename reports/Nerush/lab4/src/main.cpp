#include <iostream>
#include <iomanip>
#include <Windows.h>

using namespace std;

// Функции написаны в lab4.asm.
// Возвращают значение функции, в *branch пишут номер ветки (1, 2 или 3)
extern "C" double CalcInt(int x, int y, int* branch);        // раздел 1
extern "C" double CalcReal(double x, double y, int* branch); // раздел 2

// Та же функция на C++, чтобы сверить ответ ассемблера
double CheckFunc(double x, double y)
{
    if (x + y > 8)  return 5 * x * y - 3;
    if (x + y < -5) return 4 * x * y * y / (x * x + 1);
    return 2 * x * x - 4 * y * y + 3;
}

// Ввод числа с проверкой, повторяем, пока не введут правильно
template <typename T>
T inputNumber(const char* prompt)
{
    T value;
    while (true) {
        cout << prompt;
        if (cin >> value) {
            cin.ignore(10000, '\n');
            return value;
        }
        cin.clear();
        cin.ignore(10000, '\n');
        cout << "Ошибка: нужно ввести число." << endl;
    }
}

void printResult(int branch, double res, double check)
{
    const char* formula[] = { "", "5xy - 3", "4xy^2 / (x^2 + 1)", "2x^2 - 4y^2 + 3" };
    const char* cond[] = { "", "x + y > 8", "x + y < -5", "-5 <= x + y <= 8" };

    cout << "Ветка " << branch << ": " << cond[branch]
         << "  ->  y = " << formula[branch] << endl;
    cout << fixed << setprecision(6);
    cout << "Результат (ассемблер): " << res << endl;
    cout << "Проверка  (C++):       " << check << endl;
    cout.unsetf(ios::fixed);
}

int main()
{
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    cout << "Вариант 15. Вычисление функции:" << endl;
    cout << "      | 5xy - 3,            x + y > 8" << endl;
    cout << "  y = | 4xy^2 / (x^2 + 1),  x + y < -5" << endl;
    cout << "      | 2x^2 - 4y^2 + 3,    -5 <= x + y <= 8" << endl;

    char answer;
    do {
        cout << "\n1 - раздел 1 (целочисленные команды)" << endl;
        cout << "2 - раздел 2 (вещественные команды)" << endl;
        int mode = inputNumber<int>("Выберите раздел: ");
        int branch = 0;

        if (mode == 1) {
            int x = inputNumber<int>("Введите x (целое): ");
            int y = inputNumber<int>("Введите y (целое): ");
            double res = CalcInt(x, y, &branch);
            printResult(branch, res, CheckFunc(x, y));
        }
        else if (mode == 2) {
            double x = inputNumber<double>("Введите x (вещественное): ");
            double y = inputNumber<double>("Введите y (вещественное): ");
            double res = CalcReal(x, y, &branch);
            printResult(branch, res, CheckFunc(x, y));
        }
        else {
            cout << "Нет такого раздела." << endl;
        }

        cout << "\nВычислить ещё раз? (y/n): ";
        cin >> answer;
        cin.ignore(10000, '\n');
    } while (answer == 'y' || answer == 'Y');

    return 0;
}
