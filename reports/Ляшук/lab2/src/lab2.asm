
.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

; Windows API
GetStdHandle PROTO STDCALL :DWORD
ReadConsoleW PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteConsoleA PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteConsoleW PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess PROTO STDCALL :DWORD

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11

.data

prompt db "Enter text (finish with a dot): ", 0

conditionTrue db 13,10
              db "Condition is TRUE.",13,10,0

conditionFalse db 13,10
               db "Condition is FALSE. Text was not changed.",13,10,0

resultMessage db "Result: ",0

emptyMessage db 13,10
             db "Error: empty text.",13,10,0

lengthMessage db 13,10
              db "Error: maximum text length is 100 characters.",13,10,0

dotMessage db 13,10
           db "Error: terminating dot was not found.",13,10,0

newline db 13,10,0

.code

; ================================================
; PROCEDURE 1: CheckCondition
;
; Проверка:
; Количество строчных русских букв равно
; количеству цифр.
;
; EAX = 1 - условие выполнено
; EAX = 0 - условие не выполнено
; ================================================

CheckCondition PROC pText:DWORD, textLen:DWORD

    LOCAL letters:DWORD
    LOCAL digits:DWORD

    push esi

    mov letters, 0
    mov digits, 0

    mov esi, pText
    mov ecx, textLen

check_loop:

    test ecx, ecx
    jz check_end

    lodsw

    ; Проверка цифр 0-9

    cmp ax, '0'
    jb check_russian

    cmp ax, '9'
    ja check_russian

    inc digits
    jmp check_next

check_russian:

    ; Проверка русских букв а-я

    cmp ax, 0430h
    jb check_yo

    cmp ax, 044Fh
    ja check_yo

    inc letters
    jmp check_next

check_yo:

    ; Проверка буквы ё

    cmp ax, 0451h
    jne check_next

    inc letters

check_next:

    dec ecx
    jmp check_loop

check_end:

    xor eax, eax

    mov edx, letters
    cmp edx, digits
    jne check_exit

    mov eax, 1

check_exit:

    pop esi
    ret

CheckCondition ENDP


; ================================================
; PROCEDURE 2: RotateText
;
; Циклический сдвиг строки на 3 позиции влево.
;
; Используются строковые команды:
; REP MOVSW
;
; Временный буфер имеет постоянный размер.
; ================================================

RotateText PROC pText:DWORD, textLen:DWORD

    LOCAL temp[3]:WORD

    push esi
    push edi
    push ebx

    ; Вычисляем 3 mod длину строки

    mov eax, 3
    xor edx, edx
    mov ebx, textLen
    div ebx

    mov ebx, edx

    ; Если сдвиг равен нулю

    test ebx, ebx
    jz rotate_exit

    cld

    ; Сохраняем первые символы

    mov esi, pText
    lea edi, temp

    mov ecx, ebx
    rep movsw

    ; Перемещаем оставшуюся часть строки

    mov esi, pText

    mov eax, ebx
    shl eax, 1
    add esi, eax

    mov edi, pText

    mov ecx, textLen
    sub ecx, ebx

    rep movsw

    ; Записываем сохранённые символы в конец

    lea esi, temp
    mov ecx, ebx

    rep movsw

rotate_exit:

    pop ebx
    pop edi
    pop esi

    ret

RotateText ENDP


; ================================================
; MAIN PROCEDURE
; ================================================

start PROC

    LOCAL hIn:DWORD
    LOCAL hOut:DWORD

    LOCAL input[256]:WORD

    LOCAL readCount:DWORD
    LOCAL written:DWORD
    LOCAL textLen:DWORD

    ; Получаем дескрипторы консоли

    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hIn, eax

    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hOut, eax

    ; Приглашение к вводу

    invoke WriteConsoleA, hOut, ADDR prompt, SIZEOF prompt-1, ADDR written, 0

    ; Считываем Unicode-текст

    invoke ReadConsoleW, hIn, ADDR input, 255, ADDR readCount, 0

    ; Ищем точку

    lea esi, input
    mov ecx, readCount
    xor ebx, ebx

find_dot:

    test ecx, ecx
    jz no_dot

    lodsw

    cmp ax, '.'
    je dot_found

    inc ebx

    ; Проверка максимальной длины

    cmp ebx, 100
    ja too_long

    dec ecx
    jmp find_dot

dot_found:

    mov textLen, ebx

    ; Проверка пустого текста

    cmp textLen, 0
    je empty_text

    ; Проверяем условие варианта 12

    invoke CheckCondition, ADDR input, textLen

    cmp eax, 1
    jne condition_failed

    ; Условие выполнено

    invoke WriteConsoleA, hOut, ADDR conditionTrue, SIZEOF conditionTrue-1, ADDR written, 0

    ; Выполняем сдвиг на три позиции влево

    invoke RotateText, ADDR input, textLen

    ; Выводим результат

    invoke WriteConsoleA, hOut, ADDR resultMessage, SIZEOF resultMessage-1, ADDR written, 0

    invoke WriteConsoleW, hOut, ADDR input, textLen, ADDR written, 0

    invoke WriteConsoleA, hOut, ADDR newline, SIZEOF newline-1, ADDR written, 0

    jmp program_exit

condition_failed:

    invoke WriteConsoleA, hOut, ADDR conditionFalse, SIZEOF conditionFalse-1, ADDR written, 0

    jmp program_exit

empty_text:

    invoke WriteConsoleA, hOut, ADDR emptyMessage, SIZEOF emptyMessage-1, ADDR written, 0

    jmp program_exit

too_long:

    invoke WriteConsoleA, hOut, ADDR lengthMessage, SIZEOF lengthMessage-1, ADDR written, 0

    jmp program_exit

no_dot:

    invoke WriteConsoleA, hOut, ADDR dotMessage, SIZEOF dotMessage-1, ADDR written, 0

program_exit:

    invoke ExitProcess, 0

start ENDP

END start
