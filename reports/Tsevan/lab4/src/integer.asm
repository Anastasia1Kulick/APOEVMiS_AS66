.386
.387
.model flat, c
option casemap:none

.const
two SDWORD 2
three SDWORD 3
four SDWORD 4
five SDWORD 5
lower_bound SDWORD -4

integer_high PROTO C :SDWORD, :SDWORD
integer_low PROTO C :SDWORD, :SDWORD
integer_middle PROTO C :SDWORD, :SDWORD

.code
calculate_integer PROC x:SDWORD, y:SDWORD
    fild x
    fisub y
    ficomp two
    fnstsw ax
    sahf
    ja select_high
    fild x
    fisub y
    ficomp lower_bound
    fnstsw ax
    sahf
    jb select_low
    invoke integer_middle, x, y
    mov eax, 3
    ret
select_high:
    invoke integer_high, x, y
    mov eax, 1
    ret
select_low:
    invoke integer_low, x, y
    mov eax, 2
    ret

calculate_integer ENDP

integer_high PROC x:SDWORD, y:SDWORD
    fild x
    fimul x
    fild y
    fimul four
    fsubp st(1), st(0)
    fiadd five
    fild x
    fimul x
    fiadd two
    fdivp st(1), st(0)
    ret

integer_high ENDP

integer_low PROC x:SDWORD, y:SDWORD
    fild x
    fimul two
    fiadd y
    fild x
    fimul x
    fimul three
    fiadd four
    fdivp st(1), st(0)
    ret

integer_low ENDP

integer_middle PROC x:SDWORD, y:SDWORD
    fild x
    fimul x
    fild y
    fimul two
    fsubp st(1), st(0)
    fiadd three
    ret
integer_middle ENDP
END
