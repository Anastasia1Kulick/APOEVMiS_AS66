; ============================================================
; Лабораторная работа №1. Раздел 1. Вариант 5
; Целочисленные команды сопроцессора (x87): fild, fimul, fiadd,
; fisub, fidiv, ficom, fistp, fisttp
;
;        | 3x + 2y^2 - 5,      xy > 8
;   f =  | (xy + 7)/(2x^2 + 4),  xy < -12   (целая часть)
;        | 4x^2 - 3y^2 + 4,     -12 <= xy <= 8
;
; OneCompiler: Assembly (NASM, x86-64 Linux)
; Рекомендуемый диапазон ввода: |x|, |y| <= 1000
; ============================================================
default rel

%macro PRINT 2
    mov     eax, 1              ; sys_write
    mov     edi, 1              ; stdout
    lea     rsi, [%1]
    mov     edx, %2
    syscall
%endmacro

section .data
    msg_x    db "Введите целое x: "
    len_x    equ $ - msg_x
    msg_y    db "Введите целое y: "
    len_y    equ $ - msg_y
    msg_b1   db "Ветка 1: xy > 8", 10
    len_b1   equ $ - msg_b1
    msg_b2   db "Ветка 2: xy < -12", 10
    len_b2   equ $ - msg_b2
    msg_b3   db "Ветка 3: -12 <= xy <= 8", 10
    len_b3   equ $ - msg_b3
    msg_res  db "Результат f = "
    len_res  equ $ - msg_res

    c2       dd 2
    c3       dd 3
    c4       dd 4
    c5       dd 5
    c7       dd 7
    c8       dd 8
    cm12     dd -12

section .bss
    inbuf    resb 256
    outbuf   resb 32
    inptr    resq 1
    x        resd 1
    y        resd 1
    xy       resq 1
    den      resd 1
    res      resq 1

section .text
global _start

_start:
    lea     rax, [inbuf]
    mov     [inptr], rax

    PRINT   msg_x, len_x
    call    read_int
    mov     [x], eax

    PRINT   msg_y, len_y
    call    read_int
    mov     [y], eax

    call    calc

    PRINT   msg_res, len_res
    mov     rax, [res]
    call    print_int

    mov     eax, 60             ; sys_exit
    xor     edi, edi
    syscall

; ------------------------------------------------------------
; calc - вычисление функции. Вход: [x], [y]. Выход: [res]
; ------------------------------------------------------------
calc:
    fild    dword [x]
    fimul   dword [y]
    fistp   qword [xy]          ; xy = x*y

    fild    qword [xy]
    ficom   dword [c8]          ; сравнение xy с 8
    fstsw   ax
    fstp    st0
    sahf
    jbe     .not_b1             ; xy <= 8
    call    branch1
    ret
.not_b1:
    fild    qword [xy]
    ficom   dword [cm12]        ; сравнение xy с -12
    fstsw   ax
    fstp    st0
    sahf
    jae     .not_b2             ; xy >= -12
    call    branch2
    ret
.not_b2:
    call    branch3
    ret

; ------------------------------------------------------------
; Ветка 1: 3x + 2y^2 - 5
; ------------------------------------------------------------
branch1:
    PRINT   msg_b1, len_b1
    fild    dword [x]
    fimul   dword [c3]          ; 3x
    fild    dword [y]
    fimul   dword [y]           ; y^2
    fimul   dword [c2]          ; 2y^2
    faddp   st1, st0            ; 3x + 2y^2
    fisub   dword [c5]          ; - 5
    fistp   qword [res]
    ret

; ------------------------------------------------------------
; Ветка 2: (xy + 7) / (2x^2 + 4), целая часть частного
; ------------------------------------------------------------
branch2:
    PRINT   msg_b2, len_b2
    fild    dword [x]
    fimul   dword [x]           ; x^2
    fimul   dword [c2]          ; 2x^2
    fiadd   dword [c4]          ; 2x^2 + 4
    fistp   dword [den]
    fild    qword [xy]
    fiadd   dword [c7]          ; xy + 7
    fidiv   dword [den]         ; / (2x^2 + 4)
    fisttp  qword [res]         ; с отбрасыванием дробной части
    ret

; ------------------------------------------------------------
; Ветка 3: 4x^2 - 3y^2 + 4
; ------------------------------------------------------------
branch3:
    PRINT   msg_b3, len_b3
    fild    dword [y]
    fimul   dword [y]           ; y^2
    fimul   dword [c3]          ; 3y^2
    fchs                        ; -3y^2
    fild    dword [x]
    fimul   dword [x]           ; x^2
    fimul   dword [c4]          ; 4x^2
    faddp   st1, st0            ; 4x^2 - 3y^2
    fiadd   dword [c4]          ; + 4
    fistp   qword [res]
    ret

; ------------------------------------------------------------
; read_int - чтение целого числа со знаком из stdin -> RAX
; ------------------------------------------------------------
read_int:
    mov     rsi, [inptr]
    xor     r8d, r8d            ; признак минуса
    xor     eax, eax
.skip:
    movzx   ecx, byte [rsi]
    test    ecx, ecx
    jz      .refill
    cmp     ecx, '-'
    jne     .chk
    mov     r8d, 1
    inc     rsi
    jmp     .dig
.chk:
    mov     edx, ecx
    sub     edx, '0'
    cmp     edx, 9
    jbe     .dig
    inc     rsi
    jmp     .skip
.dig:
    movzx   ecx, byte [rsi]
    sub     ecx, '0'
    cmp     ecx, 9
    ja      .end
    imul    rax, rax, 10
    add     rax, rcx
    inc     rsi
    jmp     .dig
.refill:
    xor     eax, eax            ; sys_read
    xor     edi, edi            ; stdin
    lea     rsi, [inbuf]
    mov     edx, 255
    syscall
    test    rax, rax
    jle     .eof
    mov     byte [rsi + rax], 0
    xor     eax, eax
    jmp     .skip
.eof:
    mov     byte [rsi], 0
    xor     eax, eax
.end:
    mov     [inptr], rsi
    test    r8d, r8d
    jz      .ret
    neg     rax
.ret:
    ret

; ------------------------------------------------------------
; print_int - вывод целого числа со знаком из RAX + перевод строки
; ------------------------------------------------------------
print_int:
    lea     rdi, [outbuf + 31]
    mov     byte [rdi], 10
    xor     r8d, r8d
    test    rax, rax
    jns     .conv
    neg     rax
    mov     r8d, 1
.conv:
    mov     r9d, 10
.loop:
    xor     edx, edx
    div     r9
    add     dl, '0'
    dec     rdi
    mov     [rdi], dl
    test    rax, rax
    jnz     .loop
    test    r8d, r8d
    jz      .out
    dec     rdi
    mov     byte [rdi], '-'
.out:
    lea     rdx, [outbuf + 32]
    sub     rdx, rdi
    mov     rsi, rdi
    mov     eax, 1
    mov     edi, 1
    syscall
    ret
