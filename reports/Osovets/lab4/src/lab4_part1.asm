.intel_syntax noprefix

.section __TEXT,__const
c_one:       .long 1
c_two:       .long 2
c_three:     .long 3
c_four:      .long 4
c_six:       .long 6
c_nine:      .long 9
c_minus_one: .long -1
c_limit:     .long 10000

.section __TEXT,__cstring,cstring_literals
s_title:  .asciz "Лабораторная работа 4. Сопроцессор. Раздел 1: целочисленные команды. Вариант 1\nОсовец А.О., группа АС-66\n\n"
s_func:   .asciz "        | 6xy - 4y,                        x + y > 9\n    y = < (2xy + 3 + x) / (x^2 + 3y^2 + 1),  x + y < -1\n        | 3x^2 - 2y + 6,                   -1 <= x + y <= 9\n\nx и y - целые числа, |x|, |y| <= 10000.\n"
s_prompt: .asciz "\nВведите x и y через пробел (q - выход): "
s_fmt_in: .asciz "%d %d"
s_sum:    .asciz "x = %d, y = %d, x + y = %d\n"
s_b1:     .asciz "Ветвь 1 (x + y > 9):         y = 6xy - 4y = %d\n"
s_b2:     .asciz "Ветвь 2 (x + y < -1):        y = (2xy + 3 + x) / (x^2 + 3y^2 + 1) = %.6f\n"
s_b3:     .asciz "Ветвь 3 (-1 <= x + y <= 9):  y = 3x^2 - 2y + 6 = %d\n"
s_range:  .asciz "Ошибка: |x| и |y| не должны превышать 10000.\n"
s_bye:    .asciz "\nВвод завершён.\n"

.text
.globl _main

_main:
    push rbp
    mov  rbp, rsp
    push rbx
    push r12
    sub  rsp, 32

    lea  rdi, [rip + s_title]
    xor  eax, eax
    call _printf
    lea  rdi, [rip + s_func]
    xor  eax, eax
    call _printf

Lmain_loop:
    lea  rdi, [rip + s_prompt]
    xor  eax, eax
    call _printf
    lea  rdi, [rip + s_fmt_in]
    lea  rsi, [rbp - 20]
    lea  rdx, [rbp - 24]
    xor  eax, eax
    call _scanf
    cmp  eax, 2
    jne  Lmain_bye

    mov  eax, dword ptr [rbp - 20]
    cmp  eax, dword ptr [rip + c_limit]
    jg   Lmain_range
    neg  eax
    cmp  eax, dword ptr [rip + c_limit]
    jg   Lmain_range
    mov  eax, dword ptr [rbp - 24]
    cmp  eax, dword ptr [rip + c_limit]
    jg   Lmain_range
    neg  eax
    cmp  eax, dword ptr [rip + c_limit]
    jg   Lmain_range

    lea  rdi, [rip + s_sum]
    mov  esi, dword ptr [rbp - 20]
    mov  edx, dword ptr [rbp - 24]
    lea  ecx, [rsi + rdx]
    xor  eax, eax
    call _printf

    lea  rdi, [rbp - 20]
    lea  rsi, [rbp - 24]
    call calc_y
    mov  ebx, eax

    cmp  ebx, 2
    je   Lmain_real
    fistp dword ptr [rbp - 28]
    lea  rdi, [rip + s_b1]
    lea  rax, [rip + s_b3]
    cmp  ebx, 3
    cmove rdi, rax
    mov  esi, dword ptr [rbp - 28]
    xor  eax, eax
    call _printf
    jmp  Lmain_loop

Lmain_real:
    fstp qword ptr [rbp - 40]
    lea  rdi, [rip + s_b2]
    movsd xmm0, qword ptr [rbp - 40]
    mov  eax, 1
    call _printf
    jmp  Lmain_loop

Lmain_range:
    lea  rdi, [rip + s_range]
    xor  eax, eax
    call _printf
    jmp  Lmain_loop

Lmain_bye:
    lea  rdi, [rip + s_bye]
    xor  eax, eax
    call _printf
    xor  eax, eax
    add  rsp, 32
    pop  r12
    pop  rbx
    pop  rbp
    ret

calc_y:
    push rbp
    mov  rbp, rsp
    fild  dword ptr [rdi]
    fiadd dword ptr [rsi]
    ficom dword ptr [rip + c_nine]
    fstsw ax
    sahf
    ja   Lcy_b1
    ficomp dword ptr [rip + c_minus_one]
    fstsw ax
    sahf
    jb   Lcy_b2
    call branch3
    mov  eax, 3
    pop  rbp
    ret
Lcy_b1:
    fstp st(0)
    call branch1
    mov  eax, 1
    pop  rbp
    ret
Lcy_b2:
    call branch2
    mov  eax, 2
    pop  rbp
    ret

branch1:
    fild  dword ptr [rdi]
    fimul dword ptr [rsi]
    fimul dword ptr [rip + c_six]
    fild  dword ptr [rsi]
    fimul dword ptr [rip + c_four]
    fsubp st(1), st
    ret

branch2:
    push rbp
    mov  rbp, rsp
    sub  rsp, 16
    fild  dword ptr [rdi]
    fimul dword ptr [rdi]
    fild  dword ptr [rsi]
    fimul dword ptr [rsi]
    fimul dword ptr [rip + c_three]
    faddp st(1), st
    fiadd dword ptr [rip + c_one]
    fistp dword ptr [rbp - 4]
    fild  dword ptr [rdi]
    fimul dword ptr [rsi]
    fimul dword ptr [rip + c_two]
    fiadd dword ptr [rip + c_three]
    fiadd dword ptr [rdi]
    fidiv dword ptr [rbp - 4]
    leave
    ret

branch3:
    fild  dword ptr [rdi]
    fimul dword ptr [rdi]
    fimul dword ptr [rip + c_three]
    fild  dword ptr [rsi]
    fimul dword ptr [rip + c_two]
    fsubp st(1), st
    fiadd dword ptr [rip + c_six]
    ret
