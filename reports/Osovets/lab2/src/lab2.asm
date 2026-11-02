.intel_syntax noprefix

.equ MAX_LEN, 100
.equ BUF_SIZE, 400
.equ STDIN, 0
.equ STDOUT, 1

.section __TEXT,__cstring,cstring_literals
s_title:     .asciz "Лабораторная работа 2. Обработка символьных данных. Вариант 1\nОсовец А.О., группа АС-66\n\n"
s_cond:      .asciz "Проверяемое условие: текст оканчивается прописной латинской буквой,\n                     которая больше в тексте не встречается.\n"
s_rule:      .asciz "Правило: каждая ненулевая цифра заменяется строчной латинской буквой\n         (1 -> a, 2 -> b, ..., 9 -> i).\n\n"
s_prompt:    .asciz "Введите текст (не более 100 символов, признак конца ввода - точка):\n> "
s_src:       .asciz "\nИсходный текст:        \""
s_res:       .asciz "Преобразованный текст: \""
s_quote_nl:  .asciz "\"\n"
s_true:      .asciz "Условие истинно - текст преобразуется.\n"
s_false:     .asciz "Условие ложно - текст не преобразуется.\n"
s_err_nodot: .asciz "\nОшибка: ввод закончился без точки. Последовательность не является текстом.\n"
s_err_empty: .asciz "\nОшибка: перед точкой нет ни одного символа. Пустая последовательность не является текстом.\n"
s_err_long:  .asciz "\nОшибка: больше 100 символов. Последовательность не является текстом.\n"

.text
.globl _main

_main:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    sub  rsp, BUF_SIZE
    mov  r12, rsp

    lea  rdi, [rip + s_title]
    call print_cstr
    lea  rdi, [rip + s_cond]
    call print_cstr
    lea  rdi, [rip + s_rule]
    call print_cstr
    lea  rdi, [rip + s_prompt]
    call print_cstr

    mov  rdi, r12
    mov  rsi, BUF_SIZE
    call read_text
    test rax, rax
    js   Lmain_bad
    mov  rbx, rax

    lea  rdi, [rip + s_src]
    call print_cstr
    mov  rdi, r12
    mov  rsi, rbx
    call print_buf
    lea  rdi, [rip + s_quote_nl]
    call print_cstr

    mov  rdi, r12
    mov  rsi, rbx
    call check_condition
    test eax, eax
    jz   Lmain_false

    lea  rdi, [rip + s_true]
    call print_cstr
    mov  rdi, r12
    mov  rsi, rbx
    call transform_text
    lea  rdi, [rip + s_res]
    call print_cstr
    mov  rdi, r12
    mov  rsi, rbx
    call print_buf
    lea  rdi, [rip + s_quote_nl]
    call print_cstr
    xor  eax, eax
    jmp  Lmain_done

Lmain_false:
    lea  rdi, [rip + s_false]
    call print_cstr
    xor  eax, eax
    jmp  Lmain_done

Lmain_bad:
    lea  rdi, [rip + s_err_nodot]
    cmp  rax, -1
    je   Lmain_msg
    lea  rdi, [rip + s_err_empty]
    cmp  rax, -2
    je   Lmain_msg
    lea  rdi, [rip + s_err_long]
Lmain_msg:
    call print_cstr
    mov  eax, 1

Lmain_done:
    add  rsp, BUF_SIZE
    pop  r12
    pop  rbx
    pop  rbp
    ret

read_text:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    mov  rbx, rdi
    mov  r12, rsi
    xor  r13, r13
    xor  r14, r14
Lrt_next:
    cmp  r13, r12
    jae  Lrt_long
    mov  edi, STDIN
    lea  rsi, [rbx + r13]
    mov  edx, 1
    call _read
    cmp  rax, 1
    jne  Lrt_nodot
    movzx eax, byte ptr [rbx + r13]
    cmp  al, '.'
    je   Lrt_end
    and  al, 0xC0
    cmp  al, 0x80
    je   Lrt_store
    cmp  r14, MAX_LEN
    jae  Lrt_long
    inc  r14
Lrt_store:
    inc  r13
    jmp  Lrt_next
Lrt_end:
    test r13, r13
    jz   Lrt_empty
    mov  rax, r13
    jmp  Lrt_ret
Lrt_nodot:
    mov  rax, -1
    jmp  Lrt_ret
Lrt_empty:
    mov  rax, -2
    jmp  Lrt_ret
Lrt_long:
    mov  rax, -3
Lrt_ret:
    pop  r14
    pop  r13
    pop  r12
    pop  rbx
    pop  rbp
    ret

check_condition:
    xor  eax, eax
    test rsi, rsi
    jz   Lcc_ret
    mov  dl, byte ptr [rdi + rsi - 1]
    cmp  dl, 'A'
    jb   Lcc_ret
    cmp  dl, 'Z'
    ja   Lcc_ret
    lea  rcx, [rsi - 1]
    jrcxz Lcc_true
    mov  al, dl
    cld
    repne scasb
    mov  eax, 0
    je   Lcc_ret
Lcc_true:
    mov  eax, 1
Lcc_ret:
    ret

transform_text:
    mov  rcx, rsi
    mov  rsi, rdi
    cld
    jrcxz Ltt_ret
Ltt_loop:
    lodsb
    cmp  al, '1'
    jb   Ltt_put
    cmp  al, '9'
    ja   Ltt_put
    add  al, 'a' - '1'
Ltt_put:
    stosb
    loop Ltt_loop
Ltt_ret:
    ret

print_cstr:
    mov  rdx, rdi
    xor  eax, eax
    mov  rcx, -1
    cld
    repne scasb
    not  rcx
    dec  rcx
    mov  rdi, rdx
    mov  rsi, rcx
    jmp  print_buf

print_buf:
    push rbp
    mov  rbp, rsp
    mov  rdx, rsi
    mov  rsi, rdi
    mov  edi, STDOUT
    call _write
    pop  rbp
    ret
