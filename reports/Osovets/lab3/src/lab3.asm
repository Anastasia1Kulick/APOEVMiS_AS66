.intel_syntax noprefix

.equ BUF_SIZE, 1024
.equ STDIN, 0
.equ STDOUT, 1

.macro PRINT msg
    lea  rdi, [rip + \msg]
    call print_cstr
.endm

.macro PRINT_BUF ptr, len
    push \len
    push \ptr
    pop  rdi
    pop  rsi
    call print_buf
.endm

.macro PRINT_NUM val
    mov  rdi, \val
    call print_uint
.endm

.macro READ_LINE buf, cap
    push \cap
    push \buf
    pop  rdi
    pop  rsi
    call read_line
.endm

.macro CHAR_LEN src, res
    movzx eax, byte ptr [\src]
    mov  \res, 1
    mov  edx, eax
    and  edx, 0xE0
    cmp  edx, 0xC0
    jne  Lcl_3\@
    mov  \res, 2
    jmp  Lcl_end\@
Lcl_3\@:
    mov  edx, eax
    and  edx, 0xF0
    cmp  edx, 0xE0
    jne  Lcl_4\@
    mov  \res, 3
    jmp  Lcl_end\@
Lcl_4\@:
    mov  edx, eax
    and  edx, 0xF8
    cmp  edx, 0xF0
    jne  Lcl_end\@
    mov  \res, 4
Lcl_end\@:
.endm

.macro COUNT_CHAR text, tlen, sym, slen, res
    push \sym
    push \slen
    push \tlen
    push \text
    pop  rdi
    pop  rcx
    pop  r11
    pop  r10
    xor  r8d, r8d
    test r11, r11
    jz   Lcc_done\@
    dec  r11
    mov  al, byte ptr [r10]
    cld
Lcc_scan\@:
    test rcx, rcx
    jz   Lcc_done\@
    repne scasb
    jne  Lcc_done\@
    cmp  rcx, r11
    jb   Lcc_done\@
    test r11, r11
    jz   Lcc_hit\@
    mov  r9, rdi
    mov  rdx, rcx
    lea  rsi, [r10 + 1]
    mov  rcx, r11
    repe cmpsb
    jne  Lcc_miss\@
    mov  rcx, rdx
    sub  rcx, r11
    jmp  Lcc_hit\@
Lcc_miss\@:
    mov  rdi, r9
    mov  rcx, rdx
    jmp  Lcc_scan\@
Lcc_hit\@:
    inc  r8
    jmp  Lcc_scan\@
Lcc_done\@:
    mov  \res, r8
.endm

.section __TEXT,__cstring,cstring_literals
s_title:     .asciz "Лабораторная работа 3. Макроопределения. Вариант 1\nОсовец А.О., группа АС-66\n\n"
s_task:      .asciz "Задание: подсчитать количество вхождений заданного символа в строку текста.\n\n"
s_ask_text:  .asciz "Введите строку текста:\n> "
s_ask_sym:   .asciz "Введите символ для поиска:\n> "
s_line:      .asciz "\nСтрока:  \""
s_symbol:    .asciz "Символ:  \""
s_quote_nl:  .asciz "\"\n"
s_count:     .asciz "\nКоличество вхождений символа в строку: "
s_spaces:    .asciz "Количество пробелов в строке:           "
s_nl:        .asciz "\n"
s_space:     .asciz " "
s_err_eof:   .asciz "\nОшибка: ввод прерван, строка не получена.\n"
s_err_long:  .asciz "\nОшибка: строка длиннее 1024 байт.\n"
s_err_sym:   .asciz "\nОшибка: символ для поиска не введён.\n"

.text
.globl _main

_main:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub  rsp, 2 * BUF_SIZE + 24

    PRINT s_title
    PRINT s_task

    PRINT s_ask_text
    lea  r12, [rbp - 2 * BUF_SIZE - 64]
    READ_LINE r12, BUF_SIZE
    cmp  rax, -1
    je   Lmain_eof
    cmp  rax, -2
    je   Lmain_long
    mov  rbx, rax

    PRINT s_ask_sym
    lea  r13, [rbp - BUF_SIZE - 64]
    READ_LINE r13, BUF_SIZE
    cmp  rax, -2
    je   Lmain_long
    test rax, rax
    jle  Lmain_nosym
    mov  r15, rax
    CHAR_LEN r13, r14
    cmp  r14, r15
    ja   Lmain_nosym

    PRINT s_line
    PRINT_BUF r12, rbx
    PRINT s_quote_nl
    PRINT s_symbol
    PRINT_BUF r13, r14
    PRINT s_quote_nl

    COUNT_CHAR r12, rbx, r13, r14, r15
    PRINT s_count
    PRINT_NUM r15
    PRINT s_nl

    mov  qword ptr [rbp - 64], r12
    mov  qword ptr [rbp - 56], rbx
    lea  rax, [rip + s_space]
    COUNT_CHAR "qword ptr [rbp - 64]", "qword ptr [rbp - 56]", rax, 1, "qword ptr [rbp - 48]"
    PRINT s_spaces
    PRINT_NUM "qword ptr [rbp - 48]"
    PRINT s_nl

    xor  eax, eax
    jmp  Lmain_done

Lmain_eof:
    PRINT s_err_eof
    mov  eax, 1
    jmp  Lmain_done
Lmain_long:
    PRINT s_err_long
    mov  eax, 1
    jmp  Lmain_done
Lmain_nosym:
    PRINT s_err_sym
    mov  eax, 1

Lmain_done:
    add  rsp, 2 * BUF_SIZE + 24
    pop  r15
    pop  r14
    pop  r13
    pop  r12
    pop  rbx
    pop  rbp
    ret

read_line:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    mov  rbx, rdi
    mov  r12, rsi
    xor  r13, r13
Lrl_next:
    cmp  r13, r12
    jae  Lrl_long
    mov  edi, STDIN
    lea  rsi, [rbx + r13]
    mov  edx, 1
    call _read
    cmp  rax, 1
    jne  Lrl_eof
    cmp  byte ptr [rbx + r13], 10
    je   Lrl_end
    inc  r13
    jmp  Lrl_next
Lrl_eof:
    test r13, r13
    jnz  Lrl_end
    mov  rax, -1
    jmp  Lrl_ret
Lrl_end:
    mov  rax, r13
    jmp  Lrl_ret
Lrl_long:
    mov  rax, -2
Lrl_ret:
    pop  r14
    pop  r13
    pop  r12
    pop  rbx
    pop  rbp
    ret

print_uint:
    push rbp
    mov  rbp, rsp
    sub  rsp, 32
    mov  rax, rdi
    mov  rsi, rbp
    mov  ecx, 10
Lpu_loop:
    xor  edx, edx
    div  rcx
    add  dl, '0'
    dec  rsi
    mov  byte ptr [rsi], dl
    test rax, rax
    jnz  Lpu_loop
    mov  rdi, rsi
    mov  rsi, rbp
    sub  rsi, rdi
    call print_buf
    leave
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
