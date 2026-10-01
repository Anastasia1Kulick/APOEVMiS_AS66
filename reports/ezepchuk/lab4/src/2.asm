.386
.model flat, stdcall
option casemap:none

includelib ucrt.lib
includelib legacy_stdio_definitions.lib
includelib kernel32.lib

printf PROTO C :PTR BYTE, :VARARG
scanf PROTO C :PTR BYTE, :VARARG
ExitProcess PROTO STDCALL :DWORD

.data
prompt db "Enter real x and y (e.g. 2.5 -3.75): ", 0
fmt_in db "%lf %lf", 0
fmt_out db "Real result: y = %.6f", 13, 10, 0

two REAL8 2.0
three REAL8 3.0
four REAL8 4.0
five REAL8 5.0
one REAL8 1.0
nine REAL8 9.0
minus5 REAL8 -5.0

.code

BranchHigh PROC px:DWORD, py:DWORD

    mov eax, px
    fld qword ptr [eax]
    fmul qword ptr [five]

    mov eax, px
    fld qword ptr [eax]

    mov eax, py
    fmul qword ptr [eax]
    fmul qword ptr [two]

    faddp st(1), st(0)
    fadd qword ptr [one]

    ret

BranchHigh ENDP


BranchLow PROC px:DWORD, py:DWORD

    mov eax, px
    fld qword ptr [eax]

    mov eax, py
    fmul qword ptr [eax]
    fmul qword ptr [two]
    fadd qword ptr [three]

    mov eax, py
    fld qword ptr [eax]
    fmul st(0), st(0)
    fadd qword ptr [four]

    fdivp st(1), st(0)

    ret

BranchLow ENDP


BranchMiddle PROC px:DWORD, py:DWORD

    mov eax, px
    fld qword ptr [eax]
    fmul st(0), st(0)
    fmul qword ptr [three]

    mov eax, py
    fld qword ptr [eax]
    fmul st(0), st(0)
    fmul qword ptr [two]

    fsubp st(1), st(0)
    fadd qword ptr [one]

    ret

BranchMiddle ENDP


CalcFunc PROC px:DWORD, py:DWORD

    LOCAL sum:REAL8

    mov eax, px
    fld qword ptr [eax]

    mov eax, py
    fadd qword ptr [eax]

    fstp qword ptr [sum]

    fld qword ptr [sum]
    fcom qword ptr [nine]
    fstsw ax
    fstp st(0)

    test ax, 0100h
    jnz check_low

    test ax, 4000h
    jnz check_low

    invoke BranchHigh, px, py
    ret


check_low:

    fld qword ptr [sum]
    fcom qword ptr [minus5]
    fstsw ax
    fstp st(0)

    test ax, 0100h
    jnz use_low

    invoke BranchMiddle, px, py
    ret


use_low:

    invoke BranchLow, px, py
    ret

CalcFunc ENDP


main PROC

    LOCAL x:REAL8
    LOCAL y:REAL8
    LOCAL result:REAL8

    finit

    invoke printf, ADDR prompt
    invoke scanf, ADDR fmt_in, ADDR x, ADDR y

    invoke CalcFunc, ADDR x, ADDR y

    fstp qword ptr [result]

    push dword ptr [result+4]
    push dword ptr [result]
    push OFFSET fmt_out
    call printf
    add esp, 12

    invoke ExitProcess, 0

main ENDP

END main
