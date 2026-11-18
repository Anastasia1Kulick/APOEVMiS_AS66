#include <iostream>
#include <string>
#include <cstring>
#include <windows.h>

using namespace std;

// Функция проверки на C++ (работает с обычными английскими буквами и цифрами)
bool check_condition_cpp(const string& text) {
    for (char c : text) {
        if (c == '.') break;
        bool is_digit = (c >= '0' && c <= '9');
        bool is_upper = (c >= 'A' && c <= 'Z'); // Проверяем английские заглавные

        if (!is_digit && !is_upper) {
            return false;
        }
    }
    return true;
}

// Ассемблерная функция: заменяет заглавные английские на строчные
void transform_text_asm(char* text) {
    __asm {
        mov esi, text
        loop_start :
        mov al, [esi]
            cmp al, 0
            je loop_end
            cmp al, '.'
            je remove_dot

            cmp al, 'A'
            jb skip_transform
            cmp al, 'Z'
            ja skip_transform

            // Преобразование: 'A' (65) -> 'a' (97), разница 32
            add al, 32
            mov[esi], al

            skip_transform :
        inc esi
            jmp loop_start

            remove_dot :
        mov byte ptr[esi], 0
            jmp loop_end

            loop_end :
    }
}

int main() {
    setlocale(LC_ALL, "Russian");

    // Включаем поддержку русского языка в консоли для вывода сообщений
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    char buffer[256];
    cout << "Введите текст (латиница и цифры, точка - конец ввода): ";
    cin.getline(buffer, 256);

    string text(buffer);

    size_t dot_pos = text.find('.');
    if (dot_pos != string::npos) {
        text = text.substr(0, dot_pos);
    }

    cout << "\nПроверка условия: текст содержит только цифры и прописные буквы.\n";

    if (check_condition_cpp(text)) {
        cout << "Условие выполнено!\n";

        char asm_buffer[256];
        strcpy_s(asm_buffer, text.c_str());

        transform_text_asm(asm_buffer);

        cout << "Преобразованный текст: " << asm_buffer << endl;
    }
    else {
        cout << "Условие НЕ выполнено (найдены недопустимые символы).\n";
    }

    return 0;
}