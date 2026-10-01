bits 32
global _main

extern _printf
extern _scanf
extern _getchar
extern _exit
extern _fflush

section .data
    msg_cond_info  db "Condition: Text must start and end with a Latin letter.", 0Ah, 0
    msg_prompt     db "Enter text (ending with '.'): ", 0
    msg_true       db "Condition is TRUE: Processing text...", 0Ah, 0
    msg_false      db "Condition is FALSE: Text will not be processed.", 0Ah, 0
    msg_result     db "Result: %s", 0Ah, 0
    msg_empty      db "Error: empty text.", 0Ah, 0
    msg_too_long   db "Error: text is too long (max 100 chars).", 0Ah, 0

    format_char    db "%c", 0
    format_str     db "%s", 0

section .bss
    text_buf       resb 101       ; до 100 символов + завершающий 0

section .text
_main:
    push ebp
    mov ebp, esp

    push msg_cond_info
    call _printf
    add esp, 4

    push msg_prompt
    call _printf
    add esp, 4

    push 0
    call _fflush
    add esp, 4

    ; 2. Ввод строки посимвольно до точки
    mov edi, text_buf
    xor ebx, ebx                  ; EBX = длина (callee-saved)

.input_loop:
    call _getchar
    cmp al, '.'
    je .input_done
    cmp al, 0Ah
    je .input_done
    cmp al, 0Dh
    je .input_done
    cmp al, 0
    je .input_done

    cmp ebx, 100
    jge .too_long

    mov [edi + ebx], al
    inc ebx
    jmp .input_loop

.too_long:
    push msg_too_long
    call _printf
    add esp, 4
    jmp .exit_prog

.input_done:
    mov byte [edi + ebx], 0

    cmp ebx, 0
    jne .not_empty
    push msg_empty
    call _printf
    add esp, 4
    jmp .exit_prog

.not_empty:
    ; 3. Проверка условия
    mov esi, text_buf
    mov ecx, ebx
    call CheckCondition
    cmp eax, 1
    jne .condition_false

    push msg_true
    call _printf
    add esp, 4

    ; 4. Преобразование
    mov esi, text_buf
    mov ecx, ebx
    call TransformText

    jmp .print_output

.condition_false:
    push msg_false
    call _printf
    add esp, 4

.print_output:
    push text_buf
    push msg_result
    call _printf
    add esp, 8

.exit_prog:
    push 0
    call _exit

; =====================================================================
; CheckCondition
;   Вход:  ESI = указатель на текст, ECX = длина текста (>0)
;   Выход: EAX = 1, если первый и последний символы - латинские буквы,
;          иначе EAX = 0
; =====================================================================
CheckCondition:
    push ebx
    push edx

    cmp ecx, 0
    jle .fail

    ; Проверка первого символа
    mov al, [esi]
    call IsLatinLetter
    cmp eax, 0
    je .fail

    ; Проверка последнего символа
    mov edx, ecx
    dec edx
    mov al, [esi + edx]
    call IsLatinLetter
    cmp eax, 0
    je .fail

    mov eax, 1
    jmp .done

.fail:
    xor eax, eax

.done:
    pop edx
    pop ebx
    ret

; =====================================================================
; IsLatinLetter
;   Вход:  AL = символ
;   Выход: EAX = 1, если AL - латинская буква (A-Z, a-z), иначе 0
; =====================================================================
IsLatinLetter:
    cmp al, 'A'
    jb .check_lower
    cmp al, 'Z'
    jbe .yes

.check_lower:
    cmp al, 'a'
    jb .no
    cmp al, 'z'
    jbe .yes

.no:
    xor eax, eax
    ret

.yes:
    mov eax, 1
    ret

; =====================================================================
; TransformText
;   Заменяет каждую прописную русскую букву (Windows-1251: 0xC0..0xDF)
;   цифрой (N mod 10), где N - номер буквы в русском алфавите.
;   Вход:  ESI = указатель на текст, ECX = длина текста
;   Выход: текст изменён на месте
; =====================================================================
TransformText:
    push edi
    push ebx
    push edx
    xor edx, edx

.trans_loop:
    cmp edx, ecx
    jge .trans_end
    mov al, [esi + edx]

    cmp al, 80h
    jb .check_second
    cmp al, 8Fh
    jbe .calc_first

.check_second:
    cmp al, 90h
    jb .check_yo
    cmp al, 9Fh
    jbe .calc_second

.check_yo:
    cmp al, 0F0h
    je .calc_yo
    jmp .next_char

.calc_first:
    sub al, 80h
    inc al
    jmp .apply_digit

.calc_second:
    sub al, 90h
    add al, 17
    jmp .apply_digit

.calc_yo:
    mov al, 7

.apply_digit:
    xor ah, ah
    mov bl, 10
    div bl
    add ah, '0'
    mov [esi + edx], ah

.next_char:
    inc edx
    jmp .trans_loop

.trans_end:
    pop edx
    pop ebx
    pop edi
    ret