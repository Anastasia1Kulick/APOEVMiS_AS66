.386
.387
.model flat, c
option casemap:none

.const
two REAL8 2.0
three REAL8 3.0
four REAL8 4.0
five REAL8 5.0
lower_bound REAL8 -4.0

real_high PROTO C :REAL8, :REAL8
real_low PROTO C :REAL8, :REAL8
real_middle PROTO C :REAL8, :REAL8

.code
calculate_real PROC x:REAL8, y:REAL8
    fld x
    fsub y
    fcomp two
    fnstsw ax
    sahf
    ja select_high
    fld x
    fsub y
    fcomp lower_bound
    fnstsw ax
    sahf
    jb select_low
    invoke real_middle, x, y
    mov eax, 3
    ret
select_high:
    invoke real_high, x, y
    mov eax, 1
    ret
select_low:
    invoke real_low, x, y
    mov eax, 2
    ret

calculate_real ENDP

real_high PROC x:REAL8, y:REAL8
    fld x
    fmul x
    fld y
    fmul four
    fsubp st(1), st(0)
    fadd five
    fld x
    fmul x
    fadd two
    fdivp st(1), st(0)
    ret

real_high ENDP

real_low PROC x:REAL8, y:REAL8
    fld x
    fmul two
    fadd y
    fld x
    fmul x
    fmul three
    fadd four
    fdivp st(1), st(0)
    ret

real_low ENDP

real_middle PROC x:REAL8, y:REAL8
    fld x
    fmul x
    fld y
    fmul two
    fsubp st(1), st(0)
    fadd three
    ret
real_middle ENDP
END
