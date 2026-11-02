.686
.model flat, c
option casemap:none

includelib D:\masm32\lib\msvcrt.lib
includelib D:\masm32\lib\kernel32.lib

printf PROTO C :ptr sbyte, :vararg
scanf  PROTO C :ptr sbyte, :vararg
system PROTO C :ptr sbyte
exit   PROTO C :dword

.data
    msg_x       db "Enter integer X: ", 0
    msg_y       db "Enter integer Y: ", 0
    fmt_in      db "%d", 0
    fmt_res     db "Result Z = %d", 10, 0
    fmt_undef   db "Undefined for 1 < x + y <= 10", 10, 0
    cmd_pause   db "pause", 0

    val_x       dd 0
    val_y       dd 0
    res_z       dd 0
    sum_xy      dd 0

    c_1         dd 1
    c_2         dd 2
    c_3         dd 3
    c_4         dd 4
    c_5         dd 5
    c_6         dd 6

.code

; --- Ветка 1: 4*x*y + 5 ---
Branch1_Int PROC
    fild dword ptr [val_x]
    fimul dword ptr [val_y]
    fimul dword ptr [c_4]
    fiadd dword ptr [c_5]
    fistp dword ptr [res_z]
    ret
Branch1_Int ENDP

; --- Ветка 2: (3xy + 2y) / (x^2 + y^2 + 1) ---
Branch2_Int PROC
    fild dword ptr [val_x]
    fimul dword ptr [val_y]
    fimul dword ptr [c_3]       ; st(0) = 3xy

    fild dword ptr [val_y]
    fimul dword ptr [c_2]       ; st(0) = 2y, st(1) = 3xy
    faddp st(1), st(0)          ; st(0) = 3xy + 2y (числитель)

    fild dword ptr [val_x]
    fimul dword ptr [val_x]     ; st(0) = x^2, st(1) = числитель

    fild dword ptr [val_y]
    fimul dword ptr [val_y]     ; st(0) = y^2, st(1) = x^2, st(2) = числитель
    faddp st(1), st(0)          ; st(0) = x^2 + y^2, st(1) = числитель
    fiadd dword ptr [c_1]       ; st(0) = x^2 + y^2 + 1 (знаменатель)

    fdivp st(1), st(0)          ; st(0) = числитель / знаменатель
    fistp dword ptr [res_z]
    ret
Branch2_Int ENDP

; --- Ветка 3: 6*x - 2*(y^2) + 1 ---
Branch3_Int PROC
    fild dword ptr [val_x]
    fimul dword ptr [c_6]       ; st(0) = 6x

    fild dword ptr [val_y]
    fimul dword ptr [val_y]
    fimul dword ptr [c_2]       ; st(0) = 2*(y^2), st(1) = 6x

    fsubp st(1), st(0)          ; st(0) = 6x - 2y^2
    fiadd dword ptr [c_1]       ; st(0) = 6x - 2y^2 + 1
    fistp dword ptr [res_z]
    ret
Branch3_Int ENDP

; --- Основная функция вычисления ---
Calculate_Int PROC
    finit

    mov eax, [val_x]
    add eax, [val_y]
    mov [sum_xy], eax

    ; Условие 1: x + y > 10
    cmp eax, 10
    jg  do_b1

    ; Условие 2: x + y < -2
    cmp eax, -2
    jl  do_b2

    ; Условие 3: -2 <= x + y <= 1
    cmp eax, 1
    jle do_b3

    ; Вне диапазона (1 < x + y <= 10)
    invoke printf, offset fmt_undef
    ret

do_b1:
    call Branch1_Int
    jmp print_res
do_b2:
    call Branch2_Int
    jmp print_res
do_b3:
    call Branch3_Int

print_res:
    invoke printf, offset fmt_res, [res_z]
    ret
Calculate_Int ENDP

main PROC
    invoke printf, offset msg_x
    invoke scanf, offset fmt_in, offset val_x
    invoke printf, offset msg_y
    invoke scanf, offset fmt_in, offset val_y

    call Calculate_Int

    ; Пауза, чтобы окно консоли не закрывалось само
    invoke system, offset cmd_pause
    invoke exit, 0
main ENDP
END main