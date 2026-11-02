.686
.model flat, stdcall
option casemap:none
.const
iTwo SDWORD 2
iThree SDWORD 3
iFour SDWORD 4
iFive SDWORD 5
iMinusFour SDWORD -4
rTwo REAL8 2.0
rThree REAL8 3.0
rFour REAL8 4.0
rFive REAL8 5.0
rMinusFour REAL8 -4.0
.code
; Private branch procedures. Each leaves one value in ST(0).
; Part 1 uses integer operands through FILD and FI arithmetic.
IntAbove PROC PRIVATE x:SDWORD, y:SDWORD
    fild x
    fimul x
    fisub y
    fisub y
    fisub y
    fisub y
    fiadd iFive
    fild x
    fimul x
    fiadd iTwo
    fdivp st(1), st(0)
    ret
IntAbove ENDP
IntBelow PROC PRIVATE x:SDWORD, y:SDWORD
    fild x
    fiadd x
    fiadd y
    fild x
    fimul x
    fimul iThree
    fiadd iFour
    fdivp st(1), st(0)
    ret
IntBelow ENDP
IntMiddle PROC PRIVATE x:SDWORD, y:SDWORD
    fild x
    fimul x
    fisub y
    fisub y
    fiadd iThree
    ret
IntMiddle ENDP
; Part 2 uses real memory operands through FLD and F arithmetic.
RealAbove PROC PRIVATE x:PTR REAL8, y:PTR REAL8
    mov ecx, x
    mov edx, y
    fld REAL8 PTR [ecx]
    fmul REAL8 PTR [ecx]
    fld REAL8 PTR [edx]
    fmul rFour
    fsubp st(1), st(0)
    fadd rFive
    fld REAL8 PTR [ecx]
    fmul REAL8 PTR [ecx]
    fadd rTwo
    fdivp st(1), st(0)
    ret
RealAbove ENDP
RealBelow PROC PRIVATE x:PTR REAL8, y:PTR REAL8
    mov ecx, x
    mov edx, y
    fld REAL8 PTR [ecx]
    fmul rTwo
    fadd REAL8 PTR [edx]
    fld REAL8 PTR [ecx]
    fmul REAL8 PTR [ecx]
    fmul rThree
    fadd rFour
    fdivp st(1), st(0)
    ret
RealBelow ENDP
RealMiddle PROC PRIVATE x:PTR REAL8, y:PTR REAL8
    mov ecx, x
    mov edx, y
    fld REAL8 PTR [ecx]
    fmul REAL8 PTR [ecx]
    fld REAL8 PTR [edx]
    fmul rTwo
    fsubp st(1), st(0)
    fadd rThree
    ret
RealMiddle ENDP
; ABI: stdcall. Result and branch are output pointers; EAX=0 success,
; EAX=1 nonfinite input/output. Branch 1: d>2, 2: d<-4, 3: middle.
; Caller supplies valid pointers and an empty x87 stack (normal x86 ABI).
; Control word is restored; x87 stack is empty on return.
EvaluateInteger PROC x:SDWORD, y:SDWORD, result:PTR REAL8, branch:PTR DWORD
    LOCAL oldCW:WORD, workCW:WORD
    fnstcw oldCW
    mov ax, oldCW
    and ax, 0F0FFh
    or ax, 033Fh
    mov workCW, ax
    fldcw workCW
    fild x
    fisub y
    ficomp iTwo
    fnstsw ax
    sahf
    ja int_above
    fild x
    fisub y
    ficomp iMinusFour
    fnstsw ax
    sahf
    jb int_below
    invoke IntMiddle, x, y
    mov eax, 3
    jmp int_finish
int_above:
    invoke IntAbove, x, y
    mov eax, 1
    jmp int_finish
int_below:
    invoke IntBelow, x, y
    mov eax, 2
int_finish:
    mov edx, branch
    mov [edx], eax
    mov edx, result
    fstp REAL8 PTR [edx]
    fldcw oldCW
    xor eax, eax
    ret
EvaluateInteger ENDP
EvaluateReal PROC x:PTR REAL8, y:PTR REAL8, result:PTR REAL8, branch:PTR DWORD
    LOCAL oldCW:WORD, workCW:WORD
    mov ecx, x
    mov edx, y
    mov eax, [ecx + 4]
    and eax, 7FF00000h
    cmp eax, 7FF00000h
    je real_invalid
    mov eax, [edx + 4]
    and eax, 7FF00000h
    cmp eax, 7FF00000h
    je real_invalid
    fnstcw oldCW
    mov ax, oldCW
    and ax, 0F0FFh
    or ax, 033Fh
    mov workCW, ax
    fldcw workCW
    fld REAL8 PTR [ecx]
    fsub REAL8 PTR [edx]
    fcomp rTwo
    fnstsw ax
    sahf
    ja real_above
    fld REAL8 PTR [ecx]
    fsub REAL8 PTR [edx]
    fcomp rMinusFour
    fnstsw ax
    sahf
    jb real_below
    invoke RealMiddle, x, y
    mov eax, 3
    jmp real_finish
real_above:
    invoke RealAbove, x, y
    mov eax, 1
    jmp real_finish
real_below:
    invoke RealBelow, x, y
    mov eax, 2
real_finish:
    mov edx, branch
    mov [edx], eax
    mov edx, result
    fstp REAL8 PTR [edx]
    fldcw oldCW
    mov eax, [edx + 4]
    and eax, 7FF00000h
    cmp eax, 7FF00000h
    je real_invalid
    xor eax, eax
    ret
real_invalid:
    mov eax, 1
    ret
EvaluateReal ENDP
END
