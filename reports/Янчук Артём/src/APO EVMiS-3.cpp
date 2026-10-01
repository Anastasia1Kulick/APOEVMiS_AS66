#include "iostream"
#include "cstring"
#include "windows.h"

using namespace std;

extern "C" void reverseWordsWrapper(char* str, char* buffer);

int main() {
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);


    char myStr[200] = { 0 };
    char tempBuffer[200] = { 0 };

    cout << "Введите строку (слова, разделенные пробелами):\n> ";
    cin.getline(myStr, 200);

    reverseWordsWrapper(myStr, tempBuffer);

    cout << "\nРезультат\n> " << myStr << "\n";

    return 0;
}