.MODEL SMALL
.STACK 100h

.DATA
    msg_intro   DB 'Lab 2. Option 5', 13, 10
                DB 'Condition: Count of uppercase Latin letters == Count of lowercase Latin letters.', 13, 10
                DB 'Rule: Shift uppercase Russian letters (A-Ya) to next in alphabet, Ya -> A.', 13, 10, 13, 10, '$'
    
    msg_source  DB 'Source text: ', '$'
    msg_cond_ok DB 13, 10, 'Condition MET: Uppercase Latin count equals Lowercase Latin count.', 13, 10, '$'
    msg_cond_no DB 13, 10, 'Condition NOT MET. Text remains unchanged.', 13, 10, '$'
    msg_result  DB 'Result: ', '$'
    msg_crlf    DB 13, 10, '$'

    ; --- Заранее заданная строка ---
    ; "AaAa " + 'а' (A0h) + 'б' (A1h) + 'в' (A2h) + ' ' + 'А' (80h) + 'Я' (9Fh)
    ; Вы можете менять байты русскоязычных букв по таблице CP866.
    text_data   DB 'AaAa ', 0A0h, 0A1h, 0A2h, ' ', 80h, 9Fh, '$'
    
    ; Длина строки (без завершающего '$')
    text_len    DW 11

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

    ; --- 1. Установка видеорежима / страницы для корректного вывода ---
    MOV AX, 0003h       ; Текстовый режим 80x25 (стандартный DOS)
    INT 10h

    ; --- 2. Вывод описания ---
    LEA DX, msg_intro
    MOV AH, 09h
    INT 21h

    ; --- 3. Вывод исходной строки ---
    LEA DX, msg_source
    MOV AH, 09h
    INT 21h

    LEA DX, text_data
    MOV AH, 09h
    INT 21h

    LEA DX, msg_crlf
    MOV AH, 09h
    INT 21h

    ; --- 4. Проверка условия ---
    LEA SI, text_data
    MOV CX, text_len
    CALL CHECK_CONDITION

    CMP AL, 1
    JNE CONDITION_FAILED

    ; --- 5. Преобразование текста ---
    LEA DX, msg_cond_ok
    MOV AH, 09h
    INT 21h

    LEA SI, text_data
    MOV CX, text_len
    CALL TRANSFORM_TEXT

    ; --- 6. Вывод результата ---
    LEA DX, msg_result
    MOV AH, 09h
    INT 21h

    LEA DX, text_data
    MOV AH, 09h
    INT 21h

    LEA DX, msg_crlf
    MOV AH, 09h
    INT 21h
    JMP EXIT_PROGRAM

CONDITION_FAILED:
    LEA DX, msg_cond_no
    MOV AH, 09h
    INT 21h

EXIT_PROGRAM:
    MOV AX, 4C00h
    INT 21h
MAIN ENDP

; =========================================================================
; Процедура: CHECK_CONDITION
; Вход:  SI = адрес начала строки
;        CX = длина строки
; Выход: AL = 1, если число заглавных латинских == числу строчных латинских
;        AL = 0, если условие не выполнено
; =========================================================================
CHECK_CONDITION PROC
    PUSH BX
    PUSH CX
    PUSH SI
    XOR BX, BX           ; BL = заглавные Latin, BH = строчные Latin

CHECK_LOOP:
    LODSB
    CMP AL, 'A'
    JB  NOT_UPPER
    CMP AL, 'Z'
    JA  NOT_UPPER
    INC BL
    JMP NEXT_CHAR

NOT_UPPER:
    CMP AL, 'a'
    JB  NEXT_CHAR
    CMP AL, 'z'
    JA  NEXT_CHAR
    INC BH

NEXT_CHAR:
    LOOP CHECK_LOOP

    CMP BL, BH
    JE  COND_SUCCESS
    MOV AL, 0
    JMP COND_EXIT

COND_SUCCESS:
    MOV AL, 1

COND_EXIT:
    POP SI
    POP CX
    POP BX
    RET
CHECK_CONDITION ENDP

; =========================================================================
; Процедура: TRANSFORM_TEXT
; Вход:  SI = адрес начала строки
;        CX = длина строки
; Действие: Заменяет 'А'..'Ю' на следующий символ по алфавиту, 'Я' на 'А'
; =========================================================================
TRANSFORM_TEXT PROC
    PUSH AX
    PUSH CX
    PUSH SI

TRANS_LOOP:
    MOV AL, [SI]

    ; 1. Буква 'Я' (9Fh в CP866) -> меняется на 'А' (80h)
    CMP AL, 9Fh
    JNE CHECK_RUS
    MOV BYTE PTR [SI], 80h
    JMP NEXT_TRANS_CHAR

CHECK_RUS:
    ; 2. Диапазон 'А' (80h) .. 'Ю' (9Eh) -> сдвиг на +1 ('А'->'Б', 'П'->'Р' и т.д.)
    CMP AL, 80h
    JB  NEXT_TRANS_CHAR
    CMP AL, 9Eh
    JA  NEXT_TRANS_CHAR

    INC AL
    MOV [SI], AL

NEXT_TRANS_CHAR:
    INC SI
    LOOP TRANS_LOOP

    POP SI
    POP CX
    POP AX
    RET
TRANSFORM_TEXT ENDP

END MAIN

;keyb ru 866