; lab3_asm.asm
; Лабораторная работа №3 (ассемблер, макроопределения). Вариант 9.
; Куган Н. Л., АС-66.
;
; Задание:
;     задана строка слов; словом считается последовательность символов,
;     разделённая пробелами. Из исходной строки удалить слова,
;     начинающиеся с заданного символа.
;
; Пробелы между словами не изменяются (удаляется само слово),
; символ сравнивается с первым символом слова с учётом регистра.
;
; extern "C" int RemoveWordsAsm(char* text, int len, char target);
;
; Платформа проекта - x86 (Win32), сборка через ml.exe.

.386
.MODEL FLAT, C
.CODE

; -------------------------------------------------------------------
; Макроопределение REMOVE_WORDS
; Параметры:
;   strAddr    - адрес начала строки (регистр или память)
;   strLen     - длина строки (регистр, память или константа)
;   targetChar - искомый символ (регистр или память, один байт)
;   result     - регистр-приёмник новой длины строки
;
; Строка преобразуется на месте. Макрос использует регистры
; esi (чтение), edi (запись), ebx (начало строки), ecx (счётчик),
; edx (dl - искомый символ) и al (текущий символ), поэтому result
; должен быть регистром, отличным от esi, edi, ebx, ecx и edx.
; Вызывающая процедура сама сохраняет esi, edi и ebx.
; -------------------------------------------------------------------
REMOVE_WORDS MACRO strAddr, strLen, targetChar, result
    LOCAL nextItem, wordStart, copyWord, skipWord, scanDone

    mov     esi, strAddr         ; esi = откуда читаем
    mov     edi, esi             ; edi = куда пишем
    mov     ebx, esi             ; ebx = начало строки (для вычисления длины)
    mov     ecx, strLen          ; ecx = сколько символов ещё не обработано
    mov     dl, targetChar       ; dl = искомый символ

nextItem:
    test    ecx, ecx
    jz      scanDone             ; строка закончилась
    mov     al, [esi]
    cmp     al, 20h              ; пробел?
    jne     wordStart
    mov     [edi], al            ; пробел переписываем без изменений
    inc     esi
    inc     edi
    dec     ecx
    jmp     nextItem

wordStart:                       ; al - первый символ слова
    cmp     al, dl
    je      skipWord             ; слово начинается с искомого символа - удаляем

copyWord:                        ; копируем слово до пробела или конца строки
    test    ecx, ecx
    jz      scanDone
    mov     al, [esi]
    cmp     al, 20h
    je      nextItem
    mov     [edi], al
    inc     esi
    inc     edi
    dec     ecx
    jmp     copyWord

skipWord:                        ; пропускаем слово до пробела или конца строки
    test    ecx, ecx
    jz      scanDone
    cmp     byte ptr [esi], 20h
    je      nextItem
    inc     esi
    dec     ecx
    jmp     skipWord

scanDone:
    mov     result, edi
    sub     result, ebx          ; result = edi - начало = новая длина строки
ENDM


; -------------------------------------------------------------------
; int RemoveWordsAsm(char* text, int len, char target)
; Процедура-обёртка: принимает параметры по cdecl и вызывает макрос
; REMOVE_WORDS, который разворачивается прямо здесь, в теле процедуры.
; Возвращает в eax новую длину текста.
; -------------------------------------------------------------------
PUBLIC RemoveWordsAsm
RemoveWordsAsm PROC
    push    ebp
    mov     ebp, esp
    push    esi                  ; esi, edi, ebx - callee-saved по cdecl
    push    edi
    push    ebx

    REMOVE_WORDS [ebp+8], [ebp+12], byte ptr [ebp+16], eax

    pop     ebx
    pop     edi
    pop     esi
    pop     ebp
    ret
RemoveWordsAsm ENDP

END
