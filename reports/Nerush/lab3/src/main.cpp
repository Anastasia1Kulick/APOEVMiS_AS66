#include <iostream>
#include <cstring>
#include <Windows.h>

using namespace std;

#define MAX_LEN 256 // больше 256 символов не принимаем

// Функция написана в lab3.asm, внутри нее используется макрос REPLACE_WORDS.
// Возвращает, сколько слов заменилось
extern "C" int ReplaceWordsEnd(char* str, char letter);

int main()
{
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    char str[MAX_LEN + 1];
    char letter;
    char answer;

    cout << "Задание: слова, заканчивающиеся на заданную букву, "
            "заменить знаком &." << endl;
    cout << "Словом считается последовательность символов между пробелами." << endl;

    do {
        cout << "\nВведите строку слов (не более " << MAX_LEN << " символов):" << endl;
        cin.getline(str, MAX_LEN + 1);
        if (cin.fail()) {                    // ввели слишком длинную строку
            cin.clear();
            cin.ignore(10000, '\n');
            cout << "Ошибка: строка длиннее " << MAX_LEN << " символов." << endl;
        }
        else {
            cout << "Введите букву: ";
            cin >> letter;
            cin.ignore(10000, '\n');

            cout << "Исходная строка:        \"" << str << "\"" << endl;
            int count = ReplaceWordsEnd(str, letter); // тут вызывается ассемблерная часть
            cout << "Заменено слов на '" << letter << "': " << count << endl;
            cout << "Преобразованная строка: \"" << str << "\"" << endl;
        }

        cout << "\nОбработать ещё одну строку? (y/n): ";
        cin >> answer;
        cin.ignore(10000, '\n');
    } while (answer == 'y' || answer == 'Y');

    return 0;
}
