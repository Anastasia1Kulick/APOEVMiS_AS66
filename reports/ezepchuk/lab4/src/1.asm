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
prompt db "Enter x and y: ", 0
fmt_in db "%d %d", 0
fmt_out db "y = %.6f", 13, 10, 0

five dd 5
four dd 4
three dd 3
two dd 2
one dd 1

.code

CalcHigh PROC x:SDWORD, y:SDWORD
    LOCAL a:REAL8
    LOCAL b:REAL8

    fild x
    fimul five
    fstp a

    fild x
    fild y
    fmul
    fimul two
    fstp b

    fld a
    fadd b
    fiadd one

    ret
CalcHigh ENDP

CalcLow PROC x:SDWORD, y:SDWORD
    LOCAL a:REAL8
    LOCAL b:REAL8

    fild x
    fild y
    fmul
    fimul two
    fiadd three
    fstp a

    fild y
    fmul st(0), st(0)
    fiadd four
    fstp b

    fld a
    fdiv b

    ret
CalcLow ENDP

CalcMiddle PROC x:SDWORD, y:SDWORD
    LOCAL a:REAL8
    LOCAL b:REAL8

    fild x
    fmul st(0), st(0)
    fimul three
    fstp a

    fild y
    fmul st(0), st(0)
    fimul two
    fstp b

    fld a
    fsub b
    fiadd one

    ret
CalcMiddle ENDP

CalcFunc PROC x:SDWORD, y:SDWORD
    mov eax, x
    add eax, y

    cmp eax, 9
    jg high_branch

    cmp eax, -5
    jl low_branch

    jmp middle_branch

high_branch:
    invoke CalcHigh, x, y
    ret

low_branch:
    invoke CalcLow, x, y
    ret

middle_branch:
    invoke CalcMiddle, x, y
    ret

CalcFunc ENDP

main PROC
    LOCAL x:SDWORD
    LOCAL y:SDWORD

    invoke printf, ADDR prompt
    invoke scanf, ADDR fmt_in, ADDR x, ADDR y

    invoke CalcFunc, x, y

    sub esp, 8
    fstp qword ptr [esp]

    push offset fmt_out
    call printf
    add esp, 12

    invoke ExitProcess, 0
main ENDP

END main
