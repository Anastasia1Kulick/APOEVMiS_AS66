; lab3_asm.asm
; Лаб. №3 (ассемблер, макроопределения). Вариант 1.
; Подсчитать количество вхождений заданного символа в строку текста.
;
; extern "C" int CountCharAsm(const char* text, int length, char target);
;
; Платформа проекта — x86 (Win32), сборка через ml.exe.

.386
.MODEL FLAT, C
.CODE

; -------------------------------------------------------------------
; Макроопределение COUNT_CHAR
; Параметры:
;   strAddr    — адрес начала строки (регистр или память)
;   strLen     — длина строки (регистр или память)
;   targetChar — искомый символ (регистр с его кодом)
;   result     — регистр-приёмник результата (счётчик вхождений)
;
; result должен быть регистром, ОТЛИЧНЫМ от esi/ecx — их макрос
; использует как собственные рабочие регистры (esi — указатель по
; строке, ecx — счётчик цикла).
; -------------------------------------------------------------------
COUNT_CHAR MACRO strAddr, strLen, targetChar, result
    LOCAL scanLoop, skipChar, scanDone   ; свои метки на каждое место использования макроса —
                                          ; без LOCAL повторный вызов макроса в одном файле
                                          ; дал бы ошибку повторного определения метки

    mov esi, strAddr          ; esi -> начало строки
    mov ecx, strLen           ; ecx = сколько символов ещё нужно проверить
    xor result, result        ; result = 0 — обнуляем счётчик перед подсчётом

scanLoop:
    cmp ecx, 0
    je  scanDone                ; строка кончилась — выходим
    cmp byte ptr [esi], targetChar
    jne skipChar                 ; символ не совпал с искомым — пропускаем
    inc result                    ; совпал — увеличиваем счётчик
skipChar:
    inc esi                       ; переходим к следующему символу строки
    dec ecx
    jmp scanLoop

scanDone:
ENDM


; -------------------------------------------------------------------
; int CountCharAsm(const char* text, int length, char target)
; Процедура-обёртка: принимает параметры по cdecl и вызывает макрос
; COUNT_CHAR, который разворачивается прямо здесь, в теле процедуры.
; -------------------------------------------------------------------
PUBLIC CountCharAsm
CountCharAsm PROC
    push ebp
    mov  ebp, esp
    push esi                     ; esi — callee-saved по cdecl, сохраняем

    mov dl, byte ptr [ebp+16]    ; dl = target (char на стеке занимает минимум 4 байта, берём младший байт)

    COUNT_CHAR [ebp+8], [ebp+12], dl, eax   ; strAddr=text, strLen=length, targetChar=dl, result=eax

    pop esi
    pop ebp
    ret
CountCharAsm ENDP

END