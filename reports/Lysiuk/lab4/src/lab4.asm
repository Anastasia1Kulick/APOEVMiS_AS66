; Laboratory work No. 4. Variant 4
; Coprocessor (x87 FPU) programming.
; Function f(x, y):
;     2*x*y + 3                  if x - y > 9
;     3*y^2 / (x^2 + 2*y + 1)    if x - y < -6
;     2*x^2 - 2*y + 1            if -6 <= x - y <= 9
;
; Part 1 uses the integer FPU instructions (FILD, FIADD, FIMUL, FISUB, FISTP),
; Part 2 uses the real FPU instructions (FLD, FADD, FMUL, FSUB, FSTP).
;
; MASM, x64, Windows console (Visual Studio, ml64).

OPTION CASEMAP:NONE

includelib kernel32.lib

GetStdHandle PROTO
ReadFile     PROTO
WriteFile    PROTO
ExitProcess  PROTO

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11

INPUT_BUF_SIZE    EQU 256       ; size of the input buffer

.const

kI1     dd 1
kI2     dd 2
kI3     dd 3
kI6     dd 6
kI9     dd 9
kIm6    dd -6
kI10    dd 10
kI1000  dd 1000
kR2     REAL8 2.0
kR3     REAL8 3.0
kR6     REAL8 6.0
kR9     REAL8 9.0
kRm6    REAL8 -6.0
kR1e6   REAL8 1000000.0

msgTitle     db "Laboratory work No. 4. Variant 4", 13, 10, 13, 10, 0
msgTask      db "Function f(x, y):", 13, 10
             db "    2*x*y + 3                  if x - y > 9", 13, 10
             db "    3*y^2 / (x^2 + 2*y + 1)    if x - y < -6", 13, 10
             db "    2*x^2 - 2*y + 1            if -6 <= x - y <= 9", 13, 10
             db "Range: |x| <= 1000, |y| <= 1000. An empty line finishes the current part.", 13, 10, 0
msgPart1     db 13, 10, "Part 1: integer FPU instructions (x, y are integers, result is rounded)", 13, 10, 0
msgPart2     db 13, 10, "Part 2: real FPU instructions (x, y are real numbers)", 13, 10, 0
msgX         db "x = ", 0
msgY         db "y = ", 0
msgBranch1   db "Branch 1: x - y > 9, f = 2xy + 3", 13, 10, 0
msgBranch2   db "Branch 2: x - y < -6, f = 3y^2 / (x^2 + 2y + 1)", 13, 10, 0
msgBranch3   db "Branch 3: -6 <= x - y <= 9, f = 2x^2 - 2y + 1", 13, 10, 0
msgValue     db "f(x, y) = ", 0
msgCRLF      db 13, 10, 0
msgDivZero   db "Error: division by zero (x^2 + 2y + 1 = 0).", 13, 10, 0
msgBadNumber db "Error: this is not a number.", 13, 10, 0
msgRange     db "Error: the value is out of range [-1000; 1000].", 13, 10, 0
msgBye       db 13, 10, "The program is finished.", 13, 10, 0

.code

; ---------------------------------------------------------------------------
; PrintStr - prints a zero-terminated string to the console.
; In:  rcx = address of the string
; ---------------------------------------------------------------------------
PrintStr PROC
    push rbx
    push rsi
    sub  rsp, 38h

    mov  rsi, rcx
    xor  ebx, ebx
ps_len:
    cmp  byte ptr [rsi + rbx], 0
    je   ps_write
    inc  ebx
    jmp  ps_len

ps_write:
    mov  ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov  rcx, rax
    mov  rdx, rsi
    mov  r8d, ebx
    lea  r9, [rsp + 28h]
    mov  qword ptr [rsp + 20h], 0
    call WriteFile

    add  rsp, 38h
    pop  rsi
    pop  rbx
    ret
PrintStr ENDP

; ---------------------------------------------------------------------------
; InputLine - reads a line from the console and removes the end of line.
; In:  rcx = address of the buffer, edx = size of the buffer
; Out: eax = length of the string, or -1 if nothing was read
; ---------------------------------------------------------------------------
InputLine PROC
    push rbx
    push rsi
    sub  rsp, 38h

    mov  rsi, rcx
    mov  ebx, edx
    dec  ebx

    mov  ecx, STD_INPUT_HANDLE
    call GetStdHandle
    mov  rcx, rax
    mov  rdx, rsi
    mov  r8d, ebx
    lea  r9, [rsp + 28h]
    mov  qword ptr [rsp + 20h], 0
    call ReadFile
    test eax, eax
    jz   il_fail

    mov  ecx, dword ptr [rsp + 28h]
    test ecx, ecx
    jz   il_fail
    xor  eax, eax
il_scan:
    cmp  eax, ecx
    jae  il_end
    mov  dl, byte ptr [rsi + rax]
    cmp  dl, 13
    je   il_end
    cmp  dl, 10
    je   il_end
    inc  eax
    jmp  il_scan

il_end:
    mov  byte ptr [rsi + rax], 0
    jmp  il_exit

il_fail:
    mov  eax, -1

il_exit:
    add  rsp, 38h
    pop  rsi
    pop  rbx
    ret
InputLine ENDP

; ---------------------------------------------------------------------------
; PutUInt - writes an unsigned number as decimal digits.
; In:  rcx = destination, rax = number
; Out: rcx = address after the last digit
; ---------------------------------------------------------------------------
PutUInt PROC
    mov  r11, rax
    mov  r8d, 1
    mov  r10d, 10
pu_count:
    cmp  rax, 10
    jb   pu_write
    xor  edx, edx
    div  r10
    inc  r8d
    jmp  pu_count
pu_write:
    mov  rax, r11
    lea  r9, [rcx + r8]
    mov  r11, r9
pu_digit:
    xor  edx, edx
    div  r10
    add  dl, '0'
    dec  r9
    mov  byte ptr [r9], dl
    cmp  r9, rcx
    ja   pu_digit
    mov  rcx, r11
    ret
PutUInt ENDP

; ---------------------------------------------------------------------------
; IntToStr - converts a signed 32-bit integer to a zero-terminated string.
; In:  rcx = destination, edx = number
; ---------------------------------------------------------------------------
IntToStr PROC
    movsxd rax, edx
    test rax, rax
    jns  is_pos
    mov  byte ptr [rcx], '-'
    inc  rcx
    neg  rax
is_pos:
    call PutUInt
    mov  byte ptr [rcx], 0
    ret
IntToStr ENDP

; ---------------------------------------------------------------------------
; RealToStr - converts a REAL8 number to a string with 6 digits after the point.
; In:  rcx = destination, rdx = address of the REAL8 number
; ---------------------------------------------------------------------------
RealToStr PROC
    sub  rsp, 28h
    fld  qword ptr [rdx]
    fmul qword ptr [kR1e6]
    frndint
    fistp qword ptr [rsp + 20h]
    mov  rax, qword ptr [rsp + 20h]
    test rax, rax
    jns  rs_pos
    mov  byte ptr [rcx], '-'
    inc  rcx
    neg  rax
rs_pos:
    xor  edx, edx
    mov  r10d, 1000000
    div  r10
    mov  qword ptr [rsp + 20h], rdx
    call PutUInt
    mov  byte ptr [rcx], '.'
    inc  rcx
    mov  rax, qword ptr [rsp + 20h]
    lea  r9, [rcx + 6]
    mov  r11, r9
    mov  r10d, 10
rs_frac:
    xor  edx, edx
    div  r10
    add  dl, '0'
    dec  r9
    mov  byte ptr [r9], dl
    cmp  r9, rcx
    ja   rs_frac
    mov  byte ptr [r11], 0
    add  rsp, 28h
    ret
RealToStr ENDP

; ---------------------------------------------------------------------------
; ParseInt - converts a string to an integer in the range [-1000; 1000].
; In:  rcx = string, rdx = address of the DWORD result
; Out: eax = 0 - ok, 1 - not a number, 2 - out of range
; ---------------------------------------------------------------------------
ParseInt PROC
pi_sp1:
    cmp  byte ptr [rcx], ' '
    jne  pi_sign
    inc  rcx
    jmp  pi_sp1
pi_sign:
    xor  r8d, r8d
    mov  al, byte ptr [rcx]
    cmp  al, '-'
    jne  pi_plus
    mov  r8d, 1
    inc  rcx
    jmp  pi_digits
pi_plus:
    cmp  al, '+'
    jne  pi_digits
    inc  rcx
pi_digits:
    xor  r9d, r9d
    xor  r10d, r10d
pi_loop:
    movzx eax, byte ptr [rcx]
    sub  eax, '0'
    cmp  eax, 9
    ja   pi_after
    inc  r10d
    cmp  r9d, 1000
    ja   pi_next
    imul r9d, r9d, 10
    add  r9d, eax
pi_next:
    inc  rcx
    jmp  pi_loop
pi_after:
    test r10d, r10d
    jz   pi_bad
pi_sp2:
    cmp  byte ptr [rcx], ' '
    jne  pi_end
    inc  rcx
    jmp  pi_sp2
pi_end:
    cmp  byte ptr [rcx], 0
    jne  pi_bad
    cmp  r9d, 1000
    ja   pi_range
    test r8d, r8d
    jz   pi_store
    neg  r9d
pi_store:
    mov  dword ptr [rdx], r9d
    xor  eax, eax
    ret
pi_bad:
    mov  eax, 1
    ret
pi_range:
    mov  eax, 2
    ret
ParseInt ENDP

; ---------------------------------------------------------------------------
; ParseReal - converts a string "[-]ddd[.ddd]" to a REAL8 number in [-1000; 1000].
; In:  rcx = string, rdx = address of the REAL8 result
; Out: eax = 0 - ok, 1 - not a number, 2 - out of range
; ---------------------------------------------------------------------------
ParseReal PROC
    push rbx
    sub  rsp, 30h
    mov  rbx, rdx
pr_sp1:
    cmp  byte ptr [rcx], ' '
    jne  pr_sign
    inc  rcx
    jmp  pr_sp1
pr_sign:
    xor  r8d, r8d
    mov  al, byte ptr [rcx]
    cmp  al, '-'
    jne  pr_plus
    mov  r8d, 1
    inc  rcx
    jmp  pr_body
pr_plus:
    cmp  al, '+'
    jne  pr_body
    inc  rcx
pr_body:
    mov  r9, rcx
    xor  r10d, r10d
    xor  r11d, r11d
    xor  edx, edx
pr_scan:
    movzx eax, byte ptr [rcx]
    cmp  al, '.'
    je   pr_dot
    cmp  al, ','
    je   pr_dot
    sub  eax, '0'
    cmp  eax, 9
    ja   pr_after
    inc  r10d
    add  r11d, edx
    inc  rcx
    jmp  pr_scan
pr_dot:
    test edx, edx
    jnz  pr_bad
    mov  edx, 1
    inc  rcx
    jmp  pr_scan
pr_after:
    test r10d, r10d
    jz   pr_bad
pr_sp2:
    cmp  byte ptr [rcx], ' '
    jne  pr_end
    inc  rcx
    jmp  pr_sp2
pr_end:
    cmp  byte ptr [rcx], 0
    jne  pr_bad

    fldz
    mov  rcx, r9
    mov  edx, r10d
pr_calc:
    movzx eax, byte ptr [rcx]
    inc  rcx
    cmp  al, '.'
    je   pr_calc
    cmp  al, ','
    je   pr_calc
    sub  eax, '0'
    mov  dword ptr [rsp + 20h], eax
    fimul dword ptr [kI10]
    fiadd dword ptr [rsp + 20h]
    dec  edx
    jnz  pr_calc
    mov  ecx, r11d
    test ecx, ecx
    jz   pr_neg
pr_scale:
    fidiv dword ptr [kI10]
    dec  ecx
    jnz  pr_scale
pr_neg:
    test r8d, r8d
    jz   pr_check
    fchs
pr_check:
    fld  st(0)
    fabs
    fild dword ptr [kI1000]
    fcomip st(0), st(1)
    fstp st(0)
    jb   pr_range
    fstp qword ptr [rbx]
    xor  eax, eax
    jmp  pr_exit
pr_range:
    fstp st(0)
    mov  eax, 2
    jmp  pr_exit
pr_bad:
    mov  eax, 1
pr_exit:
    add  rsp, 30h
    pop  rbx
    ret
ParseReal ENDP

; ---------------------------------------------------------------------------
; ReadInt / ReadReal - print a prompt, read a line and convert it.
; In:  rcx = prompt, rdx = line buffer, r8 = address of the result
; Out: eax = 0 - ok, 1 - empty line (end of the part), 2 - error
; ---------------------------------------------------------------------------
ReadInt PROC
    push rbx
    push rsi
    sub  rsp, 28h
    mov  rbx, rdx
    mov  rsi, r8
    call PrintStr
    mov  rcx, rbx
    mov  edx, INPUT_BUF_SIZE
    call InputLine
    test eax, eax
    jle  ri_end
    mov  rcx, rbx
    mov  rdx, rsi
    call ParseInt
    test eax, eax
    jz   ri_exit
    lea  rcx, msgBadNumber
    cmp  eax, 2
    jne  ri_msg
    lea  rcx, msgRange
ri_msg:
    call PrintStr
    mov  eax, 2
    jmp  ri_exit
ri_end:
    mov  eax, 1
ri_exit:
    add  rsp, 28h
    pop  rsi
    pop  rbx
    ret
ReadInt ENDP

ReadReal PROC
    push rbx
    push rsi
    sub  rsp, 28h
    mov  rbx, rdx
    mov  rsi, r8
    call PrintStr
    mov  rcx, rbx
    mov  edx, INPUT_BUF_SIZE
    call InputLine
    test eax, eax
    jle  rr_end
    mov  rcx, rbx
    mov  rdx, rsi
    call ParseReal
    test eax, eax
    jz   rr_exit
    lea  rcx, msgBadNumber
    cmp  eax, 2
    jne  rr_msg
    lea  rcx, msgRange
rr_msg:
    call PrintStr
    mov  eax, 2
    jmp  rr_exit
rr_end:
    mov  eax, 1
rr_exit:
    add  rsp, 28h
    pop  rsi
    pop  rbx
    ret
ReadReal ENDP

; ---------------------------------------------------------------------------
; PrintBranch - prints the description of the branch.
; In:  ecx = number of the branch (1 - 3)
; ---------------------------------------------------------------------------
PrintBranch PROC
    sub  rsp, 28h
    lea  rdx, msgBranch1
    cmp  ecx, 2
    jne  pb_c3
    lea  rdx, msgBranch2
pb_c3:
    cmp  ecx, 3
    jne  pb_print
    lea  rdx, msgBranch3
pb_print:
    mov  rcx, rdx
    call PrintStr
    add  rsp, 28h
    ret
PrintBranch ENDP

; ===========================================================================
; Part 1. Integer FPU instructions.
; In:  rcx = address of x (DWORD), rdx = address of y (DWORD),
;      r8 = address of the result (DWORD)
; Out: eax = 0 - ok, 1 - division by zero
; ===========================================================================

; f = 2xy + 3
BranchInt1 PROC
    fild  dword ptr [rcx]
    fimul dword ptr [rdx]       ; x*y
    fimul dword ptr [kI2]       ; 2xy
    fiadd dword ptr [kI3]       ; 2xy + 3
    fistp dword ptr [r8]
    xor  eax, eax
    ret
BranchInt1 ENDP

; f = 3y^2 / (x^2 + 2y + 1)
BranchInt2 PROC
    sub  rsp, 28h
    fild  dword ptr [rdx]
    fimul dword ptr [rdx]       ; y^2
    fimul dword ptr [kI3]       ; 3y^2
    fild  dword ptr [rcx]
    fimul dword ptr [rcx]       ; x^2
    fild  dword ptr [rdx]
    fimul dword ptr [kI2]       ; 2y
    faddp st(1), st(0)          ; x^2 + 2y
    fiadd dword ptr [kI1]       ; x^2 + 2y + 1
    fistp dword ptr [rsp + 20h] ; denominator
    cmp  dword ptr [rsp + 20h], 0
    je   bi2_zero
    fidiv dword ptr [rsp + 20h] ; 3y^2 / (x^2 + 2y + 1)
    fistp dword ptr [r8]
    xor  eax, eax
    jmp  bi2_exit
bi2_zero:
    mov  eax, 1
bi2_exit:
    add  rsp, 28h
    ret
BranchInt2 ENDP

; f = 2x^2 - 2y + 1
BranchInt3 PROC
    fild  dword ptr [rcx]
    fimul dword ptr [rcx]
    fimul dword ptr [kI2]       ; 2x^2
    fild  dword ptr [rdx]
    fimul dword ptr [kI2]       ; 2y
    fsubp st(1), st(0)          ; 2x^2 - 2y
    fiadd dword ptr [kI1]       ; 2x^2 - 2y + 1
    fistp dword ptr [r8]
    xor  eax, eax
    ret
BranchInt3 ENDP

; CalcInt - chooses the branch by x - y and runs it.
CalcInt PROC
    sub  rsp, 28h
    fild  dword ptr [rcx]
    fisub dword ptr [rdx]       ; st0 = x - y
    fild  dword ptr [kI9]
    fcomip st(0), st(1)         ; compare 9 with x - y
    jb   ci_b1                  ; if 9 < x-y -> x-y > 9
    fild  dword ptr [kIm6]
    fcomip st(0), st(1)         ; compare -6 with x - y
    ja   ci_b2                  ; if -6 > x-y -> x-y < -6
    fstp st(0)
    call BranchInt3
    mov  edx, 3
    jmp  ci_exit
ci_b1:
    fstp st(0)
    call BranchInt1
    mov  edx, 1
    jmp  ci_exit
ci_b2:
    fstp st(0)
    call BranchInt2
    mov  edx, 2
ci_exit:
    add  rsp, 28h
    ret
CalcInt ENDP

; ===========================================================================
; Part 2. Real FPU instructions.
; ===========================================================================

; f = 2xy + 3
BranchReal1 PROC
    fld  qword ptr [rcx]
    fmul qword ptr [rdx]        ; x*y
    fmul qword ptr [kR2]        ; 2xy
    fld  qword ptr [kR3]
    faddp st(1), st(0)          ; 2xy + 3
    fstp qword ptr [r8]
    xor  eax, eax
    ret
BranchReal1 ENDP

; f = 3y^2 / (x^2 + 2y + 1)
BranchReal2 PROC
    fld  qword ptr [rdx]
    fmul qword ptr [rdx]        ; y^2
    fmul qword ptr [kR3]        ; 3y^2
    fld  qword ptr [rcx]
    fmul qword ptr [rcx]        ; x^2
    fld  qword ptr [rdx]
    fmul qword ptr [kR2]        ; 2y
    faddp st(1), st(0)          ; x^2 + 2y
    fld1
    faddp st(1), st(0)          ; x^2 + 2y + 1
    fldz
    fcomip st(0), st(1)         ; check denom == 0
    je   br2_zero
    fdivp st(1), st(0)          ; 3y^2 / (x^2 + 2y + 1)
    fstp qword ptr [r8]
    xor  eax, eax
    ret
br2_zero:
    fstp st(0)
    fstp st(0)
    mov  eax, 1
    ret
BranchReal2 ENDP

; f = 2x^2 - 2y + 1
BranchReal3 PROC
    fld  qword ptr [rcx]
    fmul qword ptr [rcx]
    fmul qword ptr [kR2]        ; 2x^2
    fld  qword ptr [rdx]
    fmul qword ptr [kR2]        ; 2y
    fsubp st(1), st(0)          ; 2x^2 - 2y
    fld1
    faddp st(1), st(0)          ; 2x^2 - 2y + 1
    fstp qword ptr [r8]
    xor  eax, eax
    ret
BranchReal3 ENDP

; CalcReal - chooses the branch by x - y and runs it.
CalcReal PROC
    sub  rsp, 28h
    fld  qword ptr [rcx]
    fsub qword ptr [rdx]        ; st0 = x - y
    fld  qword ptr [kR9]
    fcomip st(0), st(1)         ; compare 9 with x - y
    jb   cr_b1                  ; 9 < x-y -> x-y > 9
    fld  qword ptr [kRm6]
    fcomip st(0), st(1)         ; compare -6 with x - y
    ja   cr_b2                  ; -6 > x-y -> x-y < -6
    fstp st(0)
    call BranchReal3
    mov  edx, 3
    jmp  cr_exit
cr_b1:
    fstp st(0)
    call BranchReal1
    mov  edx, 1
    jmp  cr_exit
cr_b2:
    fstp st(0)
    call BranchReal2
    mov  edx, 2
cr_exit:
    add  rsp, 28h
    ret
CalcReal ENDP

; ---------------------------------------------------------------------------
; RunIntPart / RunRealPart - input, calculation and output.
; ---------------------------------------------------------------------------
RunIntPart PROC
    sub  rsp, 158h
    lea  rcx, msgPart1
    call PrintStr
ip_loop:
    lea  rcx, msgX
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 120h]
    call ReadInt
    cmp  eax, 1
    je   ip_done
    test eax, eax
    jnz  ip_loop
    lea  rcx, msgY
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 124h]
    call ReadInt
    cmp  eax, 1
    je   ip_done
    test eax, eax
    jnz  ip_loop

    lea  rcx, [rsp + 120h]
    lea  rdx, [rsp + 124h]
    lea  r8, [rsp + 128h]
    call CalcInt
    mov  dword ptr [rsp + 12Ch], eax
    mov  ecx, edx
    call PrintBranch
    cmp  dword ptr [rsp + 12Ch], 0
    jne  ip_zero

    lea  rcx, [rsp + 130h]
    mov  edx, dword ptr [rsp + 128h]
    call IntToStr
    lea  rcx, msgValue
    call PrintStr
    lea  rcx, [rsp + 130h]
    call PrintStr
    lea  rcx, msgCRLF
    call PrintStr
    jmp  ip_loop
ip_zero:
    lea  rcx, msgDivZero
    call PrintStr
    jmp  ip_loop
ip_done:
    add  rsp, 158h
    ret
RunIntPart ENDP

RunRealPart PROC
    sub  rsp, 168h
    lea  rcx, msgPart2
    call PrintStr
rp_loop:
    lea  rcx, msgX
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 120h]
    call ReadReal
    cmp  eax, 1
    je   rp_done
    test eax, eax
    jnz  rp_loop
    lea  rcx, msgY
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 128h]
    call ReadReal
    cmp  eax, 1
    je   rp_done
    test eax, eax
    jnz  rp_loop

    lea  rcx, [rsp + 120h]
    lea  rdx, [rsp + 128h]
    lea  r8, [rsp + 130h]
    call CalcReal
    mov  dword ptr [rsp + 138h], eax
    mov  ecx, edx
    call PrintBranch
    cmp  dword ptr [rsp + 138h], 0
    jne  rp_zero

    lea  rcx, [rsp + 140h]
    lea  rdx, [rsp + 130h]
    call RealToStr
    lea  rcx, msgValue
    call PrintStr
    lea  rcx, [rsp + 140h]
    call PrintStr
    lea  rcx, msgCRLF
    call PrintStr
    jmp  rp_loop
rp_zero:
    lea  rcx, msgDivZero
    call PrintStr
    jmp  rp_loop
rp_done:
    add  rsp, 168h
    ret
RunRealPart ENDP

; ---------------------------------------------------------------------------
; main - the program entry point.
; ---------------------------------------------------------------------------
main PROC
    sub  rsp, 28h

    lea  rcx, msgTitle
    call PrintStr
    lea  rcx, msgTask
    call PrintStr

    call RunIntPart
    call RunRealPart

    lea  rcx, msgBye
    call PrintStr
    xor  ecx, ecx
    call ExitProcess
main ENDP

END