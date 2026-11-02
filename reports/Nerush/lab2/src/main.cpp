#include <iostream>
#include <Windows.h>

using namespace std;

#define MAX_LEN 100

// ---------- 1. Ввод текста ----------
// Читает символы до точки (точка в текст не входит).
// Возвращает длину текста; -1 — текст длиннее MAX_LEN; -2 — нет точки (конец ввода)
int inputText(char* text)
{
    int len = 0;
    bool overflow = false;
    char c;

    while (cin.get(c)) {
        if (c == '.') {
            cin.ignore(10000, '\n');
            text[overflow ? 0 : len] = '\0';
            return overflow ? -1 : len;
        }
        if (len < MAX_LEN) text[len++] = c;
        else overflow = true;
    }
    return -2;
}

// ---------- Вспомогательная процедура: является ли символ русской буквой ----------
// Кодировка Windows-1251: А..я = C0h..FFh, Ё = A8h, ё = B8h
int isRusLetter(unsigned char c)
{
    int res = 0;
    __asm {
        mov al, c
        cmp al, 0C0h; А..я
        jae Yes
        cmp al, 0A8h; Ё
        je Yes
        cmp al, 0B8h; ё
        je Yes
        jmp No
        Yes :
        mov res, 1
            No :
    }
    return res;
}

// ---------- 2. Проверка условия ----------
// Текст начинается и оканчивается русской буквой
int checkCondition(const char* text, int len)
{
    int res = 0;
    __asm {
        mov esi, text; ESI = адрес начала текста
        mov ecx, len
        test ecx, ecx; пустой текст — условие ложно
        jz Done

        movzx eax, byte ptr[esi]; первый символ
        push eax
        call isRusLetter
        add esp, 4
        test eax, eax
        jz Done; первый символ не русская буква

        mov ecx, len; ECX мог быть испорчен вызовом
        movzx eax, byte ptr[esi + ecx - 1]; последний символ
        push eax
        call isRusLetter
        add esp, 4
        mov res, eax; результат проверки последнего символа
        Done :
    }
    return res;
}

// ---------- 3. Преобразование текста ----------
// В каждой группе подряд идущих одинаковых литер оставить одну.
// Используется строковая команда с префиксом повторения REPE SCASB.
// Возвращает новую длину текста.
int removeRepeats(char* text, int len)
{
    int newLen = 0;
    __asm {
        cld; DF = 0 — обработка в сторону возрастания адресов
        mov esi, text; ESI — указатель чтения
        mov ebx, esi; EBX — указатель записи
        mov edx, esi
        add edx, len; EDX — адрес конца текста

        GroupLoop :
        cmp esi, edx; дошли до конца текста ?
            jae Finish

            mov al, [esi]; AL — первая литера группы
            mov[ebx], al; записываем её один раз
            inc ebx

            mov edi, esi; EDI — откуда сканировать
            mov ecx, edx
            sub ecx, esi; ECX — сколько символов осталось
            repe scasb; пропускаем все литеры, равные AL
            je ToEnd; ZF = 1 — одинаковые литеры до конца текста

            dec edi; EDI стоит за первым отличающимся символом
            mov esi, edi; начало следующей группы
            jmp GroupLoop

            ToEnd :
        mov esi, edx
            jmp GroupLoop

            Finish :
        mov byte ptr[ebx], 0; конец строки
            sub ebx, text; новая длина = EBX - начало текста
            mov newLen, ebx
    }
    return newLen;
}

// 4. Печать результата
void printText(const char* title, const char* text)
{
    cout << title << "\"" << text << "\"" << endl;
}

int main()
{
    SetConsoleCP(1251);
    SetConsoleOutputCP(1251);

    char text[MAX_LEN + 1];
    char answer;

    cout << "Условие: текст начинается и оканчивается русской буквой." << endl;
    cout << "Преобразование: в каждой группе подряд идущих одинаковых литер "
        "оставить только одну." << endl;

    do {
        cout << "\nВведите текст (не более " << MAX_LEN
            << " символов, в конце поставьте точку):" << endl;

        int len = inputText(text);

        if (len == -2) { cout << "Ошибка: ввод завершён без точки." << endl; break; }
        if (len == -1) {
            cout << "Это не текст: длина превышает " << MAX_LEN << " символов." << endl;
        }
        else if (len == 0) {
            cout << "Это не текст: последовательность пустая." << endl;
        }
        else {
            printText("Исходный текст: ", text);

            if (checkCondition(text, len)) {
                cout << "Условие выполнено: текст начинается и оканчивается русской буквой."
                    << endl;
                len = removeRepeats(text, len);
                printText("Преобразованный текст: ", text);
                cout << "Длина после преобразования: " << len << endl;
            }
            else {
                cout << "Условие НЕ выполнено: текст не начинается или не оканчивается "
                    "русской буквой. Преобразование не выполняется." << endl;
            }
        }

        cout << "\nПроверить ещё один текст? (y/n): ";
        cin >> answer;
        cin.ignore(10000, '\n');
    } while (answer == 'y' || answer == 'Y');

    return 0;
}