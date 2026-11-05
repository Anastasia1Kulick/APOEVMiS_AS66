// Лабораторная работа №2, вариант 6.
// Условие: в тексте поровну прописных латинских и прописных русских букв.
// Правило: если условие выполнено, каждую латинскую букву заменить на букву
//          другого регистра (строчную на прописную, прописную на строчную).
// Ввод: непустой текст не длиннее 100 символов, признак конца - точка (в текст не входит).
//
// Проверка условия и преобразование написаны на ассемблере (файл text_proc.S).
// Этот файл отвечает за ввод, вывод и самопроверку.

#include <iconv.h>

#include <cstdlib>
#include <iostream>
#include <string>

using namespace std;

// ---------- Процедуры на ассемблере (text_proc.S) ----------
extern "C" {
int text_is_valid(const unsigned char* text, long len);
int check_equal_upper(const unsigned char* text, long len);
void swap_latin_case(unsigned char* text, long len);
}

// Результат разбора введённой строки.
enum Status { OK, NO_DOT, EMPTY, TOO_LONG, BAD_CHAR };

// ---------- Перекодировка ----------
// Терминал Mac работает в UTF-8, а процедуры рассчитаны на Windows-1251,
// где каждая буква, в том числе русская, занимает ровно один байт.
bool convert(const string& in, string& out, const char* to, const char* from) {
    iconv_t cd = iconv_open(to, from);
    if (cd == (iconv_t)-1) return false;

    out.assign(in.size() * 4 + 4, '\0');
    char* src = const_cast<char*>(in.data());
    size_t srcLeft = in.size();
    char* dst = &out[0];
    size_t dstLeft = out.size();

    size_t result = iconv(cd, &src, &srcLeft, &dst, &dstLeft);
    iconv_close(cd);
    if (result == (size_t)-1) return false;

    out.resize(out.size() - dstLeft);
    return true;
}

// ---------- Часть 1. Ввод ----------
// Берёт текст до первой точки и переводит его в Windows-1251.
Status parseInput(const string& line, string& text1251) {
    size_t dot = line.find('.');
    if (dot == string::npos) return NO_DOT;

    string text = line.substr(0, dot);
    if (text.empty()) return EMPTY;

    if (!convert(text, text1251, "WINDOWS-1251", "UTF-8")) return BAD_CHAR;
    if (text1251.size() > 100) return TOO_LONG;
    return OK;
}

// ---------- Часть 2. Проверка условия ----------
bool conditionHolds(string& text1251) {
    const unsigned char* p = (const unsigned char*)text1251.data();
    return check_equal_upper(p, (long)text1251.size()) == 1;
}

// ---------- Часть 3. Преобразование ----------
void transformText(string& text1251) {
    unsigned char* p = (unsigned char*)&text1251[0];
    swap_latin_case(p, (long)text1251.size());
}

// ---------- Часть 4. Вывод ----------
void printText(const string& label, const string& text1251) {
    string utf8;
    convert(text1251, utf8, "UTF-8", "WINDOWS-1251");
    cout << label << utf8 << "\n";
}

// Все четыре части подряд для одной строки; нужна для самопроверки.
// Возвращает статус; при OK в condition и result лежит итог.
Status runAll(const string& line, bool& condition, string& result) {
    string text1251;
    Status st = parseInput(line, text1251);
    if (st != OK) return st;

    if (text_is_valid((const unsigned char*)text1251.data(), (long)text1251.size()) == 0) return BAD_CHAR;

    condition = conditionHolds(text1251);
    if (condition) transformText(text1251);
    convert(text1251, result, "UTF-8", "WINDOWS-1251");
    return OK;
}

// ---------- Самопроверка ----------
// Эталон написан на C++ независимо от ассемблера и работает с UTF-32 буквами.
bool refCondition(const u32string& t) {
    int lat = 0, rus = 0;
    for (char32_t c : t) {
        if (c >= U'A' && c <= U'Z') lat++;
        if ((c >= U'А' && c <= U'Я') || c == U'Ё') rus++;
    }
    return lat == rus;
}

u32string refTransform(u32string t) {
    for (char32_t& c : t) {
        if (c >= U'A' && c <= U'Z') c = c - U'A' + U'a';
        else if (c >= U'a' && c <= U'z') c = c - U'a' + U'A';
    }
    return t;
}

string toUtf8(const u32string& t) {
    string out;
    for (char32_t c : t) {
        if (c < 0x80) out += (char)c;
        else if (c < 0x800) { out += (char)(0xC0 | (c >> 6)); out += (char)(0x80 | (c & 0x3F)); }
        else { out += (char)(0xE0 | (c >> 12)); out += (char)(0x80 | ((c >> 6) & 0x3F)); out += (char)(0x80 | (c & 0x3F)); }
    }
    return out;
}

int runTests() {
    int failed = 0, total = 0;

    // Контрольные случаи: строка, ожидаемое условие, ожидаемый результат.
    struct Case { const char* line; bool cond; const char* result; };
    Case cases[] = {
        {"AaБб.", true, "aAБб"},
        {"ABВГ.", true, "abВГ"},
        {"ABCА.", false, "ABCА"},
        {"AЁ.", true, "aЁ"},
        {"abc 123.", true, "ABC 123"},        // букв обоих видов нет: 0 = 0
        {"привет.", true, "привет"},          // строчные русские не считаются
        {"Hello Мир.", true, "hELLO Мир"},    // H и М: по одной прописной
        {"Я.", false, "Я"},
        {"Q.", false, "Q"},
        {"QЯ. хвост после точки", true, "qЯ"}, // всё после первой точки игнорируется
    };

    for (const Case& c : cases) {
        total++;
        bool cond = false;
        string result;
        Status st = runAll(c.line, cond, result);
        if (st != OK || cond != c.cond || result != c.result) {
            failed++;
            cout << "ОШИБКА на \"" << c.line << "\": получено условие " << cond << ", результат \"" << result << "\"\n";
        }
    }

    // Ошибочный ввод.
    struct Bad { const char* line; Status st; };
    Bad bad[] = {{"без точки", NO_DOT}, {".", EMPTY}, {"символ ☺.", BAD_CHAR}, {"таб\tтаб.", BAD_CHAR}};
    for (const Bad& b : bad) {
        total++;
        bool cond = false;
        string result;
        if (runAll(b.line, cond, result) != b.st) {
            failed++;
            cout << "ОШИБКА: неверный статус для \"" << b.line << "\"\n";
        }
    }
    // Граница длины: 101 символ - ошибка, 100 символов - допустимо.
    bool cond = false;
    string result;
    total++;
    if (runAll(string(101, 'a') + ".", cond, result) != TOO_LONG) { failed++; cout << "ОШИБКА: 101 символ\n"; }
    total++;
    if (runAll(string(100, 'a') + ".", cond, result) != OK) { failed++; cout << "ОШИБКА: 100 символов\n"; }

    // Случайные тексты. Алфавит подобран так, чтобы условие часто выполнялось.
    const u32string alphabet = U"ABCZabcz АБВЯЁабвёя0123,;!";
    srand(2026);
    for (int k = 0; k < 5000; k++) {
        int len = 1 + rand() % 100;
        u32string t;
        for (int i = 0; i < len; i++) t += alphabet[rand() % alphabet.size()];
        total++;
        Status st = runAll(toUtf8(t) + ".", cond, result);
        bool wantCond = refCondition(t);
        string want = toUtf8(wantCond ? refTransform(t) : t);
        if (st != OK || cond != wantCond || result != want) {
            failed++;
            cout << "ОШИБКА на случайном тексте: " << toUtf8(t) << "\n";
        }
    }

    cout << "Проверено случаев: " << total << ", ошибок: " << failed << "\n";
    return failed == 0 ? 0 : 1;
}

// ---------- Главная функция ----------
int main(int argc, char* argv[]) {
    if (argc > 1 && string(argv[1]) == "--test") return runTests();

    cout << "Лабораторная работа №2, вариант 6\n";
    cout << "Условие: прописных латинских букв столько же, сколько прописных русских (Ё входит в русские).\n";
    cout << "Если условие выполнено, у каждой латинской буквы меняется регистр.\n";
    cout << "Введите текст до 100 символов и в конце поставьте точку: ";

    // Часть 1. Ввод
    string line;
    getline(cin, line);
    string text1251;
    Status st = parseInput(line, text1251);
    if (st == NO_DOT)   { cout << "Ошибка: в конце текста нет точки.\n"; return 1; }
    if (st == EMPTY)    { cout << "Ошибка: текст пустой.\n"; return 1; }
    if (st == TOO_LONG) { cout << "Ошибка: в тексте больше 100 символов.\n"; return 1; }
    if (st == BAD_CHAR) { cout << "Ошибка: есть символ, которого нет в Windows-1251.\n"; return 1; }
    if (text_is_valid((const unsigned char*)text1251.data(), (long)text1251.size()) == 0) {
        cout << "Введённая последовательность не является текстом (есть управляющие символы), преобразование не выполняется.\n";
        return 1;
    }
    printText("Исходный текст: ", text1251);

    // Часть 2. Проверка условия
    bool ok = conditionHolds(text1251);
    cout << "Условие (поровну прописных латинских и русских букв): " << (ok ? "ВЫПОЛНЕНО" : "НЕ ВЫПОЛНЕНО") << "\n";

    // Часть 3. Преобразование
    if (ok) {
        transformText(text1251);
    } else {
        cout << "Преобразование не выполняется.\n";
    }

    // Часть 4. Вывод
    printText("Результат: ", text1251);
    return 0;
}
