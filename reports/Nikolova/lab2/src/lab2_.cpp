
#include <iostream>
#include <clocale>
using namespace std;

constexpr int MAX_LEN = 100;

int CheckConditionASM(const char* text, int length1) {
    if (length1 <= 0) return 0;

    int is_valid = 0;

    __asm {
        push esi
        push edi
        push ecx
        push eax

        mov esi, text
        mov ecx, length1
        add esi, ecx
        dec esi
        mov al, [esi]

        cmp al, 0x41
        jb cond_false
        cmp al, 0x5A
        ja cond_false

        mov ecx, length1;
        dec ecx
        cmp ecx, 0
        je cond_true

        mov edi, text
        cld
        repne scasb

        je cond_false
        jmp cond_true

        cond_false :
        mov is_valid, 0
            jmp finish

            cond_true :
        mov is_valid, 1

            finish :
            pop eax
            pop ecx
            pop edi
            pop esi
    }

    return is_valid;
}


void TransformTextASM(char* text, int length1) {
    if (length1 <= 0) return;

    __asm {
        push esi
        push ecx
        push eax

        mov esi, text
        mov ecx, length1

        transform_loop :
        cmp ecx, 0
            je done

            mov al, [esi]

            cmp al, 0x31
            jb next_char
            cmp al, 0x39
            ja next_char

            add al, 0x30
            mov[esi], al

            next_char :
        inc esi
            dec ecx
            jmp transform_loop

            done :
        pop eax
            pop ecx
            pop esi
    }
}

int main() {
    setlocale(LC_ALL, "Russian");

    char text[MAX_LEN + 1];
    int length1 = 0;

  
    
    cout << " Условие: Текст оканчивается прописной буквой ('A'..'Z'),\n";
    cout << "          которая больше в тексте не встречается.\n";
    cout << " Преобразование: Замена ненулевых цифр ('1'..'9') на ('a'..'i').\n";


    cout << "Введите текст (до " << MAX_LEN << " символов, признак конца - точка '.'):\n>";

    while (length1 < MAX_LEN) {
        int ch = cin.get();       
        if (ch == '.' || ch == '\n' || ch == EOF) {
            break;
        }
        text[length1++] = static_cast<char>(ch);
    }
    text[length1] = '\0';

    cout << "\n--- РЕЗУЛЬТАТЫ ОБРАБОТКИ ---\n";
    cout << "Введенный текст: \"" << text << "\"\n";
    cout << "Длина текста: " << length1 << " символов.\n";

    if (length1 == 0) {
        cout << "Ошибка: Введена пустая последовательность символов!\n";
        return 0;
    }

    int isConditionValid = CheckConditionASM(text, length1);

    if (isConditionValid) {
        cout << "Статус проверки: Условие ИСТИННО.\n";

        TransformTextASM(text, length1);

        cout << "Преобразованный текст: \"" << text << "\"\n";
    }
    else {
        cout << "Статус проверки: Условие ЛОЖНО.\n";
        cout << "Преобразование текста не требуется.\n";
    }

    return 0;
}