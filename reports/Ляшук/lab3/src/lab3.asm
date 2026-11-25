
.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess PROTO :DWORD
SetConsoleCP PROTO :DWORD
SetConsoleOutputCP PROTO :DWORD
lstrlenA PROTO :DWORD

; ==========================================
; Макроопределение удаления слов
; с русскими символами
; ==========================================

REMOVE_RUSSIAN_WORDS MACRO SRC, DST

LOCAL NEXT_WORD, START_WORD, SCAN_WORD
LOCAL FOUND_RUSSIAN, CHECK_RUSSIAN, ADVANCE
LOCAL WORD_END, SKIP_WORD, COPY_WORD
LOCAL FINISH

    mov esi, OFFSET SRC
    mov edi, OFFSET DST

NEXT_WORD:
    ; Пропуск пробелов

    cmp byte ptr [esi], 0
    je FINISH

    cmp byte ptr [esi], ' '
    jne START_WORD

    inc esi
    jmp NEXT_WORD

START_WORD:
    ; Запоминаем начало слова

    mov ebx, esi

    ; Флаг наличия русского символа

    xor edx, edx

SCAN_WORD:
    mov al, [esi]

    cmp al, 0
    je WORD_END

    cmp al, ' '
    je WORD_END

    ; Проверка кодировки Windows-1251

    cmp al, 0A8h
    je FOUND_RUSSIAN

    cmp al, 0B8h
    je FOUND_RUSSIAN

    cmp al, 0C0h
    jb ADVANCE

    cmp al, 0FFh
    ja ADVANCE

FOUND_RUSSIAN:
    mov edx, 1

ADVANCE:
    inc esi
    jmp SCAN_WORD

WORD_END:
    ; Если есть русский символ,
    ; пропускаем всё слово

    cmp edx, 1
    je SKIP_WORD

    ; Добавляем пробел между словами

    cmp edi, OFFSET DST
    je COPY_WORD

    mov byte ptr [edi], ' '
    inc edi

COPY_WORD:
    ; Копируем слово в результат

    cmp ebx, esi
    je NEXT_WORD

    mov al, [ebx]
    mov [edi], al

    inc ebx
    inc edi

    cmp ebx, esi
    jne COPY_WORD

SKIP_WORD:
    jmp NEXT_WORD

FINISH:
    ; Завершение строки

    mov byte ptr [edi], 0

ENDM

; ==========================================
; Секция данных
; ==========================================

.data

prompt BYTE "Enter text: ", 0
resultText BYTE 13, 10, "Result: ", 0

inputBuffer BYTE 256 DUP(0)
outputBuffer BYTE 256 DUP(0)

charsRead DWORD 0
charsWritten DWORD 0
outputLength DWORD 0

hInput DWORD 0
hOutput DWORD 0

; ==========================================
; Секция кода
; ==========================================

.code

main PROC

    ; Установка кодировки Windows-1251

    invoke SetConsoleCP, 1251
    invoke SetConsoleOutputCP, 1251

    ; Получение дескрипторов консоли

    invoke GetStdHandle, -10
    mov hInput, eax

    invoke GetStdHandle, -11
    mov hOutput, eax

    ; Вывод приглашения

    invoke WriteConsoleA, hOutput, ADDR prompt, SIZEOF prompt - 1, ADDR charsWritten, 0

    ; Ввод строки

    invoke ReadConsoleA, hInput, ADDR inputBuffer, 255, ADDR charsRead, 0

    ; Добавление нулевого символа

    mov eax, charsRead
    mov BYTE PTR [inputBuffer + eax], 0

    ; Удаление символов перевода строки

    mov esi, OFFSET inputBuffer

REMOVE_NEWLINE:
    mov al, [esi]

    cmp al, 0
    je INPUT_DONE

    cmp al, 13
    je SET_END

    cmp al, 10
    je SET_END

    inc esi
    jmp REMOVE_NEWLINE

SET_END:
    mov BYTE PTR [esi], 0

INPUT_DONE:

    ; Вызов макроопределения

    REMOVE_RUSSIAN_WORDS inputBuffer, outputBuffer

    ; Вывод заголовка результата

    invoke WriteConsoleA, hOutput, ADDR resultText, SIZEOF resultText - 1, ADDR charsWritten, 0

    ; Определение длины результата

    invoke lstrlenA, ADDR outputBuffer
    mov outputLength, eax

    ; Вывод результата

    invoke WriteConsoleA, hOutput, ADDR outputBuffer, outputLength, ADDR charsWritten, 0

    ; Завершение программы

    invoke ExitProcess, 0

main ENDP

END main
