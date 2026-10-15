bits 64
default rel

section .data
    ; Vvod/rezultat razdela 1 (16-bit signed integers)
    x_int       dw 0
    y_int       dw 0
    res_int     dw 0
    den_int     dd 0

    ; Vvod razdela 2 ispolzuet scanf("%f"), poetomu x/y - float (32 bit).
    ; Rezultat i vremenniye znacheniya - double (64 bit).
    x_real      dd 0.0
    y_real      dd 0.0
    res_real    dq 0.0
    num_real    dq 0.0
    den_real    dq 0.0

    c_8_int     dw 8
    c_12_int    dw -12
    c_1_int     dw 1
    c_2_int     dw 2
    c_3_int     dw 3
    c_4_int     dw 4

    c_8_real    dd 8.0
    c_12_real   dd -12.0
    c_1_real    dd 1.0
    c_2_real    dd 2.0
    c_3_real    dd 3.0
    c_4_real    dd 4.0

    prompt_int  db 13,10,"=== RAZDEL 1 (Tseliye) ===",13,10
                db "Vvedite x i y (tsele chisla, cherez probel): ",0
    fmt_in_int  db "%hd %hd",0
    fmt_out_int db "Rezultat f(x,y) (tseliy) = %hd",13,10,0

    prompt_real db 13,10,"=== RAZDEL 2 (Veshchestvennyye) ===",13,10
                db "Vvedite x i y (veshchestv. chisla, cherez probel): ",0
    fmt_in_real db "%f %f",0
    fmt_out_real db "Rezultat f(x,y) (veshchestv.) = %.6f",13,10,0

    error_den   db "Oshibka: znamenatel raven nuly.",13,10,0

section .text
    extern printf
    extern scanf
    extern ExitProcess
    global main

main:
    ; Windows x64: shadow space + vyravnivaniye steka.
    sub rsp, 40
    finit

    ; -------------------- RAZDEL 1 --------------------
    lea rcx, [prompt_int]
    call printf

    lea rcx, [fmt_in_int]
    lea rdx, [x_int]
    lea r8,  [y_int]
    call scanf

    call compute_integer

    lea rcx, [fmt_out_int]
    movsx edx, word [res_int]
    call printf

    ; -------------------- RAZDEL 2 --------------------
    lea rcx, [prompt_real]
    call printf

    lea rcx, [fmt_in_real]
    lea rdx, [x_real]
    lea r8,  [y_real]
    call scanf

    call compute_real

    ; Windows x64 varargs: floating-point argument is passed in XMM1
    ; and duplicated in the corresponding integer register RDX.
    lea rcx, [fmt_out_real]
    movsd xmm1, [res_real]
    mov rdx, [res_real]
    call printf

    xor ecx, ecx
    call ExitProcess


; =====================================================================
; Razdel 1: tselochislennye komandy soprotsessora
; =====================================================================
compute_integer:
    sub rsp, 8

    ; ST(0) = x*y; sravnivaem s 8.
    fild word [x_int]
    fimul word [y_int]
    fild word [c_8_int]
    fxch st1
    fcompp
    fstsw ax
    sahf
    ja .int_gt_8

    ; ST(0) = x*y; sravnivaem s -12.
    fild word [x_int]
    fimul word [y_int]
    fild word [c_12_int]
    fxch st1
    fcompp
    fstsw ax
    sahf
    jb .int_lt_minus12

    call proc_range_int
    jmp .int_done

.int_gt_8:
    call proc_gt_8_int
    jmp .int_done

.int_lt_minus12:
    call proc_lt_minus12_int

.int_done:
    add rsp, 8
    ret


; f(x,y) = 4*x*y + 4*x
proc_gt_8_int:
    fild word [x_int]
    fimul word [y_int]
    fimul word [c_4_int]       ; 4*x*y

    fild word [x_int]
    fimul word [c_4_int]       ; 4*x
    faddp st1, st0
    fistp word [res_int]
    ret


; f(x,y) = (2*x*y + 3) / (x*x + 2*y*y - 1)
; Integer section returns an integer result after x87 division/rounding.
proc_lt_minus12_int:
    ; Calculate denominator and store it as a 32-bit integer.
    fild word [x_int]
    fimul word [x_int]         ; x*x

    fild word [y_int]
    fimul word [y_int]
    fimul word [c_2_int]       ; 2*y*y
    faddp st1, st0             ; x*x + 2*y*y
    fisub word [c_1_int]       ; x*x + 2*y*y - 1
    fistp dword [den_int]

    ; Avoid division by zero.
    cmp dword [den_int], 0
    je .int_zero_den

    fild word [x_int]
    fimul word [y_int]
    fimul word [c_2_int]
    fiadd word [c_3_int]       ; 2*x*y + 3
    fidiv dword [den_int]
    fistp word [res_int]
    ret

.int_zero_den:
    mov word [res_int], 0
    ret


; f(x,y) = 3*x*x - 2*y*y + 1
proc_range_int:
    fild word [x_int]
    fimul word [x_int]
    fimul word [c_3_int]       ; 3*x*x

    fild word [y_int]
    fimul word [y_int]
    fimul word [c_2_int]       ; 2*y*y

    fsubp st1, st0             ; 3*x*x - 2*y*y
    fiadd word [c_1_int]
    fistp word [res_int]
    ret


; =====================================================================
; Razdel 2: veshchestvennye komandy soprotsessora
; =====================================================================
compute_real:
    sub rsp, 8

    ; Compare x*y with 8.
    fld dword [x_real]
    fmul dword [y_real]
    fld dword [c_8_real]
    fxch st1
    fcompp
    fstsw ax
    sahf
    ja .real_gt_8

    ; Compare x*y with -12.
    fld dword [x_real]
    fmul dword [y_real]
    fld dword [c_12_real]
    fxch st1
    fcompp
    fstsw ax
    sahf
    jb .real_lt_minus12

    call proc_range_real
    jmp .real_done

.real_gt_8:
    call proc_gt_8_real
    jmp .real_done

.real_lt_minus12:
    call proc_lt_minus12_real

.real_done:
    add rsp, 8
    ret


; f(x,y) = 4*x*y + 4*x
proc_gt_8_real:
    fld dword [x_real]
    fmul dword [y_real]
    fmul dword [c_4_real]      ; 4*x*y

    fld dword [x_real]
    fmul dword [c_4_real]      ; 4*x
    faddp st1, st0
    fstp qword [res_real]
    ret


; f(x,y) = (2*x*y + 3) / (x*x + 2*y*y - 1)
proc_lt_minus12_real:
    ; Denominator = x*x + 2*y*y - 1
    fld dword [x_real]
    fmul dword [x_real]        ; x*x

    fld dword [y_real]
    fmul dword [y_real]
    fmul dword [c_2_real]      ; 2*y*y
    faddp st1, st0
    fsub dword [c_1_real]
    fstp qword [den_real]

    ; Check denominator != 0.0
    fld qword [den_real]
    ftst
    fstsw ax
    sahf
    fstp st0
    je .real_zero_den

    ; Numerator = 2*x*y + 3
    fld dword [x_real]
    fmul dword [y_real]
    fmul dword [c_2_real]
    fadd dword [c_3_real]
    fstp qword [num_real]

    fld qword [num_real]
    fdiv qword [den_real]
    fstp qword [res_real]
    ret

.real_zero_den:
    ; Avoid invalid division; report 0 as a safe sentinel result.
    ; (For ordinary valid test inputs the denominator is nonzero.)
    fldz
    fstp qword [res_real]
    ret


; f(x,y) = 3*x*x - 2*y*y + 1
proc_range_real:
    fld dword [x_real]
    fmul dword [x_real]
    fmul dword [c_3_real]      ; 3*x*x

    fld dword [y_real]
    fmul dword [y_real]
    fmul dword [c_2_real]      ; 2*y*y

    fsubp st1, st0             ; 3*x*x - 2*y*y
    fadd dword [c_1_real]
    fstp qword [res_real]
    ret
