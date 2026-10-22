global _start

section .data
    msg_intro       db 'Lab 3. Option 5 (Macros)', 10
                    db 'Task: Move target char to the end of string if present.', 10, 10, 0
    len_intro       equ $ - msg_intro

    msg_prompt_str  db 'Input text: ', 0
    len_prompt_str  equ $ - msg_prompt_str

    msg_prompt_char db 'Target char: ', 0
    len_prompt_char equ $ - msg_prompt_char

    msg_result      db 10, 'Result text: ', 0
    len_result      equ $ - msg_result

    msg_crlf        db 10, 0
    len_crlf        equ $ - msg_crlf

    in_buffer       db 'KlArA u KaRlA uKrAlA kOrAlY a KaRl U kLaRy UkRaL kLoRnEt', 0 ;строка
    target_char     db 'K' ;то что ищем

section .bss
    text_len        resq 1                   


%macro MOVE_CHAR_TO_END 2
    push rax
    push rbx
    push rcx
    push rsi
    push rdi
    push r8

    mov rsi, %1
    
    xor rcx, rcx
%%calc_len:
    cmp byte [rsi + rcx], 0
    je %%len_found
    inc rcx
    jmp %%calc_len

%%len_found:
    cmp rcx, 1
    jbe %%done

    mov rsi, %1              
    mov rdi, %1              
    mov bl, [%2]             
    xor r8, r8               

%%process_loop:
    mov al, [rsi]
    cmp al, bl
    je %%found_target

    mov [rdi], al
    inc rdi
    jmp %%next_char

%%found_target:
    inc r8                 

%%next_char:
    inc rsi
    loop %%process_loop

    test r8, r8
    jz %%done

%%append_loop:
    mov [rdi], bl
    inc rdi
    dec r8
    jnz %%append_loop

%%done:
    pop r8
    pop rdi
    pop rsi
    pop rcx
    pop rbx
    pop rax
%endmacro

section .text
_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_intro
    mov rdx, len_intro
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_prompt_str
    mov rdx, len_prompt_str
    syscall

    mov rsi, in_buffer
    xor rdx, rdx
calc_init_len:
    cmp byte [rsi + rdx], 0
    je print_init_str
    inc rdx
    jmp calc_init_len

print_init_str:
    mov [text_len], rdx
    mov rax, 1
    mov rdi, 1
    mov rsi, in_buffer
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_crlf
    mov rdx, len_crlf
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_prompt_char
    mov rdx, len_prompt_char
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, target_char
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_crlf
    mov rdx, len_crlf
    syscall

    MOVE_CHAR_TO_END in_buffer, target_char

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_result
    mov rdx, len_result
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, in_buffer
    mov rdx, [text_len]
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_crlf
    mov rdx, len_crlf
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall