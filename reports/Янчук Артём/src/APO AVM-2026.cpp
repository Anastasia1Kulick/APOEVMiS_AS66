#include "iostream"
#include "cstring"

using namespace std;

bool checkCondition(char* str, int len) {
    bool isValid = false;
    __asm {
        mov esi, str
        mov ecx, len
        xor eax, eax
        xor edx, edx

        test ecx, ecx
        jz end_check

        check_loop :
        mov bl, [esi]

            cmp bl, '0'
            jl not_digit
            cmp bl, '9'
            jg not_digit
            inc edx
            jmp next_char

            not_digit :
        cmp bl, 'A'
            jl try_lower
            cmp bl, 'Z'
            jle is_letter

            try_lower :
        cmp bl, 'a'
            jl next_char
            cmp bl, 'z'
            jg next_char

            is_letter :
        inc eax

            next_char :
        inc esi
            dec ecx
            jnz check_loop

            end_check :
        cmp eax, edx
            jle condition_false
            mov isValid, 1

            condition_false :
    }
    return isValid;
}

void transformText(char* str, int len) {
    __asm {
        mov esi, str
        mov ecx, len
        test ecx, ecx
        jz end_transform

        transform_loop :
        mov al, [esi]

            cmp al, 'A'
            jl try_lower_t
            cmp al, 'Z'
            jg try_lower_t

            mov bl, 155
            sub bl, al
            mov[esi], bl
            jmp next_char_t

            try_lower_t :
        cmp al, 'a'
            jl next_char_t
            cmp al, 'z'
            jg next_char_t

            mov bl, 219
            sub bl, al
            mov[esi], bl

            next_char_t :
        inc esi
            dec ecx
            jnz transform_loop

            end_transform :
    }
}

int main() {
    setlocale(LC_ALL, "Russian");

    cout << "Проверяемое условие: В тексте больше латинских букв, чем цифр.\n";
    cout << "Правило преобразования: Замена латинских букв на симметричные им в алфавите.\n\n";

    char text[101];
    int len = 0;
    char ch;

    cout << "Введите текст (не более 100 символов).Обязательно ('.'):\n> ";

    while (cin.get(ch)) {
        if (ch == '.') break;
        if (ch == '\n' && len == 0) continue;
        if (len < 100) {
            text[len++] = ch;
        }
    }
    text[len] = '\0';

    cout << "\nДлина текста: " << len << " символов.\n";

    if (len == 0) {
        cout << "последовательность пуста (не является текстом).\n";
        return 0;
    }

    if (checkCondition(text, len)) {
        cout << "ВЫПОЛНЕНО.\n";
        transformText(text, len);
        cout << "Результат: " << text << "\n";
    }
    else {
        cout << "НЕ ВЫПОЛНЕНО\n";
    }

    return 0;
}