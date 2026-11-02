.386
.387
.model flat, c
option casemap:none

printf PROTO C :PTR BYTE, :VARARG
scanf PROTO C :PTR BYTE, :VARARG
fflush PROTO C :DWORD
calculate_integer PROTO C :SDWORD, :SDWORD
calculate_real PROTO C :REAL8, :REAL8

.const
title_text db "Lab 4. Variant 12. Coprocessor commands.", 10, 0
formula_text db "1: (x*x - 4*y + 5)/(x*x + 2), x-y > 2", 10
             db "2: (2*x + y)/(3*x*x + 4), x-y < -4", 10
             db "3: x*x - 2*y + 3, -4 <= x-y <= 2", 10, 0
integer_text db 10, "Part 1. Integer commands. Enter integer x and y: ", 0
real_text db 10, "Part 2. Real commands. Enter real x and y (decimal dot): ", 0
integer_format db "%d %d", 0
real_format db "%lf %lf", 0
result_text db "Branch %d. Result: %.6f", 10, 0
error_text db "Input error: enter two numbers of the required type.", 10, 0

.code
main PROC
    LOCAL integer_x:SDWORD
    LOCAL integer_y:SDWORD
    LOCAL real_x:REAL8
    LOCAL real_y:REAL8
    LOCAL result:REAL8
    LOCAL branch:DWORD

    finit
    invoke printf, ADDR title_text
    invoke printf, ADDR formula_text
    invoke printf, ADDR integer_text
    invoke fflush, 0
    invoke scanf, ADDR integer_format, ADDR integer_x, ADDR integer_y
    cmp eax, 2
    jne input_error
    invoke calculate_integer, integer_x, integer_y
    mov branch, eax
    fstp result
    invoke printf, ADDR result_text, branch, result

    invoke printf, ADDR real_text
    invoke fflush, 0
    invoke scanf, ADDR real_format, ADDR real_x, ADDR real_y
    cmp eax, 2
    jne input_error
    invoke calculate_real, real_x, real_y
    mov branch, eax
    fstp result
    invoke printf, ADDR result_text, branch, result
    xor eax, eax
    ret
input_error:
    invoke printf, ADDR error_text
    mov eax, 1
    ret
main ENDP
END
