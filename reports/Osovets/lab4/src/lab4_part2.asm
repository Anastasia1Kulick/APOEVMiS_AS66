.intel_syntax noprefix

.section __TEXT,__const
.p2align 3
d_three:  .double 3.0
d_four:   .double 4.0
d_six:    .double 6.0
d_nine:   .double 9.0
d_limit:  .double 1000000.0

.section __TEXT,__cstring,cstring_literals
s_title:  .asciz "Лабораторная работа 4. Сопроцессор. Раздел 2: вещественные команды. Вариант 1\nОсовец А.О., группа АС-66\n\n"
s_func:   .asciz "        | 6xy - 4y,                        x + y > 9\n    y = < (2xy + 3 + x) / (x^2 + 3y^2 + 1),  x + y < -1\n        | 3x^2 - 2y + 6,                   -1 <= x + y <= 9\n\nx и y - вещественные числа, |x|, |y| <= 1000000.\n"
s_prompt: .asciz "\nВведите x и y через пробел (q - выход): "
s_fmt_in: .asciz "%lf %lf"
s_sum:    .asciz "x = %.6f, y = %.6f, x + y = %.6f\n"
s_b1:     .asciz "Ветвь 1 (x + y > 9):         y = 6xy - 4y = %.6f\n"
s_b2:     .asciz "Ветвь 2 (x + y < -1):        y = (2xy + 3 + x) / (x^2 + 3y^2 + 1) = %.6f\n"
s_b3:     .asciz "Ветвь 3 (-1 <= x + y <= 9):  y = 3x^2 - 2y + 6 = %.6f\n"
s_range:  .asciz "Ошибка: |x| и |y| не должны превышать 1000000.\n"
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
    lea  rsi, [rbp - 24]
    lea  rdx, [rbp - 32]
    xor  eax, eax
    call _scanf
    cmp  eax, 2
    jne  Lmain_bye

    lea  rdi, [rbp - 24]
    call check_range
    test eax, eax
    jz   Lmain_range
    lea  rdi, [rbp - 32]
    call check_range
    test eax, eax
    jz   Lmain_range

    fld  qword ptr [rbp - 24]
    fadd qword ptr [rbp - 32]
    fstp qword ptr [rbp - 40]
    lea  rdi, [rip + s_sum]
    movsd xmm0, qword ptr [rbp - 24]
    movsd xmm1, qword ptr [rbp - 32]
    movsd xmm2, qword ptr [rbp - 40]
    mov  eax, 3
    call _printf

    lea  rdi, [rbp - 24]
    lea  rsi, [rbp - 32]
    call calc_y
    fstp qword ptr [rbp - 40]

    lea  rdi, [rip + s_b1]
    lea  rcx, [rip + s_b2]
    cmp  eax, 2
    cmove rdi, rcx
    lea  rcx, [rip + s_b3]
    cmp  eax, 3
    cmove rdi, rcx
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

check_range:
    fld  qword ptr [rdi]
    fabs
    fld  qword ptr [rip + d_limit]
    fcomip st, st(1)
    fstp st(0)
    mov  eax, 0
    jp   Lcr_ret
    jb   Lcr_ret
    mov  eax, 1
Lcr_ret:
    ret

calc_y:
    push rbp
    mov  rbp, rsp
    fld  qword ptr [rdi]
    fadd qword ptr [rsi]
    fld  qword ptr [rip + d_nine]
    fcomip st, st(1)
    jb   Lcy_b1
    fld1
    fchs
    fcomip st, st(1)
    fstp st(0)
    ja   Lcy_b2
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
    fld  qword ptr [rdi]
    fmul qword ptr [rsi]
    fmul qword ptr [rip + d_six]
    fld  qword ptr [rsi]
    fmul qword ptr [rip + d_four]
    fsubp st(1), st
    ret

branch2:
    fld  qword ptr [rdi]
    fmul qword ptr [rsi]
    fadd st, st(0)
    fadd qword ptr [rip + d_three]
    fadd qword ptr [rdi]
    fld  qword ptr [rdi]
    fmul st, st(0)
    fld  qword ptr [rsi]
    fmul st, st(0)
    fmul qword ptr [rip + d_three]
    faddp st(1), st
    fld1
    faddp st(1), st
    fdivp st(1), st
    ret

branch3:
    fld  qword ptr [rdi]
    fmul st, st(0)
    fmul qword ptr [rip + d_three]
    fld  qword ptr [rsi]
    fadd st, st(0)
    fsubp st(1), st
    fadd qword ptr [rip + d_six]
    ret
