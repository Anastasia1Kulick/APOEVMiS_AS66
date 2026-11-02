#include "iostream"
#include "cstring"
#include "windows.h"

using namespace std;

extern "C" void calculate_int(int x, int y, int* result);
extern "C" void calculate_real(float x, float y, float* result);

void testAllBranches() {

    // Ветка 1: x + y > 9
    int res_i = 0; float res_f = 0.0f;
    cout << "\n[Ветка 1] x = 5, y = 5 (x + y = 10 > 9)" << endl;
    calculate_int(5, 5, &res_i);
    calculate_real(5.0f, 5.0f, &res_f);
    cout << "Ожидается: 5*5 + 2*5*5 + 1 = 76" << endl;
    cout << "Целые (FPU): " << res_i << " | Вещественные (FPU): " << res_f << endl;

    // Ветка 2: x + y < -5
    cout << "\n[Ветка 2] x = -4, y = -2 (x + y = -6 < -5)" << endl;
    calculate_int(-4, -2, &res_i);
    calculate_real(-4.0f, -2.0f, &res_f);
    cout << "Ожидается: (2*(-4)*(-2) + 3) / ((-2)^2 + 4) = 19 / 8 = 2.375" << endl;
    cout << "Целые (FPU, с округлением): " << res_i << " | Вещественные (FPU): " << res_f << endl;

    // Ветка 3: -5 <= x + y <= 9
    cout << "\n[Ветка 3] x = 2, y = 2 (x + y = 4)" << endl;
    calculate_int(2, 2, &res_i);
    calculate_real(2.0f, 2.0f, &res_f);
    cout << "Ожидается: 3*4 - 2*4 + 1 = 5" << endl;
    cout << "Целые (FPU): " << res_i << " | Вещественные (FPU): " << res_f << endl;
}
extern "C" void reverseWordsWrapper(char* str, char* buffer);

int main() {
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    int choice;
    do {
        cout << "\n============================================\n";
        cout << "1. Ввод значений вручную (Целочисленные)\n";
        cout << "2. Ввод значений вручную (Вещественные)\n";
        cout << "3. Провести тесты по всем условиям\n";
        cout << "0. Выход\n";
        cout << "============================================\n> ";
        cin >> choice;

        if (choice == 1) {
            int x, y, res = 0;
            cout << "Введите целое X: "; cin >> x;
            cout << "Введите целое Y: "; cin >> y;
            calculate_int(x, y, &res);
            cout << "Результат (целое): " << res << endl;
        }
        else if (choice == 2) {
            float x, y, res = 0.0f;
            cout << "Введите вещественное X: "; cin >> x;
            cout << "Введите вещественное Y: "; cin >> y;
            calculate_real(x, y, &res);
            cout << "Результат (вещественное): " << res << endl;
        }
        else if (choice == 3) {
            testAllBranches();
        }
    } while (choice != 0);

    char myStr[200] = { 0 };
    char tempBuffer[200] = { 0 };

    cout << "Введите строку (слова, разделенные пробелами):\n> ";
    cin.getline(myStr, 200);

    reverseWordsWrapper(myStr, tempBuffer);

    cout << "\nРезультат\n> " << myStr << "\n";

    return 0;
}