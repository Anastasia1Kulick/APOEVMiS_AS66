; Laboratory work No. 4. Variant 4
; FPU (x87) calculations for piecewise function.
; MASM x64, Windows console. Visual Studio (ml64).

OPTION CASEMAP:NONE

includelib kernel32.lib

GetStdHandle PROTO
ReadFile     PROTO
WriteFile    PROTO
ExitProcess  PROTO

STD_IN_HANDLE   EQU -10
STD_OUT_HANDLE  EQU -11
BUF_SIZE        EQU 256

; --- constants for integer part ---
C_1     dd 1
C_2     dd 2
C_3     dd 3
C_6     dd 6
C_9     dd 9
C_M6    dd -6
C_10    dd 10
C_1000  dd 1000

; --- constants for real part ---
R_2     REAL8 2.0
R_3     REAL8 3.0
R_6     REAL8 6.0
R_9     REAL8 9.0
R_M6    REAL8 -6.0
R_MUL   REAL8 1000000.0

.const

T_TITLE     db "Laboratory work No. 4. Variant 4", 13, 10, 13, 10, 0
T_TASK      db "Calculate f(x, y):", 13, 10
            db "  2xy + 3                  if x - y > 9", 13, 10
            db "  3y^2 / (x^2 + 2y + 1)    if x - y < -6", 13, 10
            db "  2x^2 - 2y + 1            if -6 <= x - y <= 9", 13, 10
            db "Limits: |x| <= 1000, |y| <= 1000. Empty line -> next part.", 13, 10, 0
T_PART1     db 13, 10, "--- Part 1: Integer FPU instructions ---", 13, 10, 0
T_PART2     db 13, 10, "--- Part 2: Real FPU instructions ---", 13, 10, 0
T_X         db "Enter x: ", 0
T_Y         db "Enter y: ", 0
T_BR1       db "Branch 1 (x - y > 9): f = 2xy + 3", 13, 10, 0
T_BR2       db "Branch 2 (x - y < -6): f = 3y^2 / (x^2 + 2y + 1)", 13, 10, 0
T_BR3       db "Branch 3 (-6 <= x - y <= 9): f = 2x^2 - 2y + 1", 13, 10, 0
T_RES       db "Result: f = ", 0
T_NL        db 13, 10, 0
T_DIV0      db "Error: division by zero!", 13, 10, 0
T_BAD       db "Error: invalid number.", 13, 10, 0
T_RANGE     db "Error: value out of range [-1000, 1000].", 13, 10, 0
T_END       db 13, 10, "Work finished.", 13, 10, 0

.code

; --- Output a zero-terminated string ---
OutputStr PROC
    push rbx
    push rsi
    sub  rsp, 38h
    mov  rsi, rcx
    xor  ebx, ebx
os_len:
    cmp  byte ptr [rsi + rbx], 0
    je   os_write
    inc  ebx
    jmp  os_len
os_write:
    mov  ecx, STD_OUT_HANDLE
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
OutputStr ENDP

; --- Read a line and strip CR/LF ---
ReadLine PROC
    push rbx
    push rsi
    sub  rsp, 38h
    mov  rsi, rcx
    mov  ebx, edx
    dec  ebx
    mov  ecx, STD_IN_HANDLE
    call GetStdHandle
    mov  rcx, rax
    mov  rdx, rsi
    mov  r8d, ebx
    lea  r9, [rsp + 28h]
    mov  qword ptr [rsp + 20h], 0
    call ReadFile
    test eax, eax
    jz   rl_fail
    mov  ecx, dword ptr [rsp + 28h]
    test ecx, ecx
    jz   rl_fail
    xor  eax, eax
rl_scan:
    cmp  eax, ecx
    jae  rl_end
    mov  dl, byte ptr [rsi + rax]
    cmp  dl, 13
    je   rl_end
    cmp  dl, 10
    je   rl_end
    inc  eax
    jmp  rl_scan
rl_end:
    mov  byte ptr [rsi + rax], 0
    jmp  rl_exit
rl_fail:
    mov  eax, -1
rl_exit:
    add  rsp, 38h
    pop  rsi
    pop  rbx
    ret
ReadLine ENDP

; --- Convert unsigned integer to decimal string ---
UIntToStr PROC
    mov  r11, rax
    mov  r8d, 1
    mov  r10d, 10
uts_cnt:
    cmp  rax, 10
    jb   uts_wr
    xor  edx, edx
    div  r10
    inc  r8d
    jmp  uts_cnt
uts_wr:
    mov  rax, r11
    lea  r9, [rcx + r8]
    mov  r11, r9
uts_digit:
    xor  edx, edx
    div  r10
    add  dl, '0'
    dec  r9
    mov  byte ptr [r9], dl
    cmp  r9, rcx
    ja   uts_digit
    mov  rcx, r11
    ret
UIntToStr ENDP

; --- Convert signed integer to string ---
SIntToStr PROC
    movsxd rax, edx
    test rax, rax
    jns  sst_pos
    mov  byte ptr [rcx], '-'
    inc  rcx
    neg  rax
sst_pos:
    call UIntToStr
    mov  byte ptr [rcx], 0
    ret
SIntToStr ENDP

; --- Convert REAL8 to string with 6 fractional digits ---
RealToStr PROC
    sub  rsp, 28h
    fld  qword ptr [rdx]
    fmul qword ptr [R_MUL]
    frndint
    fistp qword ptr [rsp + 20h]
    mov  rax, qword ptr [rsp + 20h]
    test rax, rax
    jns  rst_pos
    mov  byte ptr [rcx], '-'
    inc  rcx
    neg  rax
rst_pos:
    xor  edx, edx
    mov  r10d, 1000000
    div  r10
    mov  qword ptr [rsp + 20h], rdx
    call UIntToStr
    mov  byte ptr [rcx], '.'
    inc  rcx
    mov  rax, qword ptr [rsp + 20h]
    lea  r9, [rcx + 6]
    mov  r11, r9
    mov  r10d, 10
rst_frac:
    xor  edx, edx
    div  r10
    add  dl, '0'
    dec  r9
    mov  byte ptr [r9], dl
    cmp  r9, rcx
    ja   rst_frac
    mov  byte ptr [r11], 0
    add  rsp, 28h
    ret
RealToStr ENDP

; --- Parse integer from string ---
ParseInt PROC
pi_space1:
    cmp  byte ptr [rcx], ' '
    jne  pi_sgn
    inc  rcx
    jmp  pi_space1
pi_sgn:
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
pi_space2:
    cmp  byte ptr [rcx], ' '
    jne  pi_end
    inc  rcx
    jmp  pi_space2
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

; --- Parse real number from string ---
ParseReal PROC
    push rbx
    sub  rsp, 30h
    mov  rbx, rdx
pr_space1:
    cmp  byte ptr [rcx], ' '
    jne  pr_sgn
    inc  rcx
    jmp  pr_space1
pr_sgn:
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
pr_space2:
    cmp  byte ptr [rcx], ' '
    jne  pr_end
    inc  rcx
    jmp  pr_space2
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
    fimul dword ptr [C_10]
    fiadd dword ptr [rsp + 20h]
    dec  edx
    jnz  pr_calc
    mov  ecx, r11d
    test ecx, ecx
    jz   pr_neg
pr_scale:
    fidiv dword ptr [C_10]
    dec  ecx
    jnz  pr_scale
pr_neg:
    test r8d, r8d
    jz   pr_check
    fchs
pr_check:
    fld  st(0)
    fabs
    fild dword ptr [C_1000]
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

; --- Read integer with prompt ---
ReadIntValue PROC
    push rbx
    push rsi
    sub  rsp, 28h
    mov  rbx, rdx
    mov  rsi, r8
    call OutputStr
    mov  rcx, rbx
    mov  edx, BUF_SIZE
    call ReadLine
    test eax, eax
    jle  ri_end
    mov  rcx, rbx
    mov  rdx, rsi
    call ParseInt
    test eax, eax
    jz   ri_ok
    lea  rcx, T_BAD
    cmp  eax, 2
    jne  ri_msg
    lea  rcx, T_RANGE
ri_msg:
    call OutputStr
    mov  eax, 2
    jmp  ri_ok
ri_end:
    mov  eax, 1
ri_ok:
    add  rsp, 28h
    pop  rsi
    pop  rbx
    ret
ReadIntValue ENDP

; --- Read real with prompt ---
ReadRealValue PROC
    push rbx
    push rsi
    sub  rsp, 28h
    mov  rbx, rdx
    mov  rsi, r8
    call OutputStr
    mov  rcx, rbx
    mov  edx, BUF_SIZE
    call ReadLine
    test eax, eax
    jle  rr_end
    mov  rcx, rbx
    mov  rdx, rsi
    call ParseReal
    test eax, eax
    jz   rr_ok
    lea  rcx, T_BAD
    cmp  eax, 2
    jne  rr_msg
    lea  rcx, T_RANGE
rr_msg:
    call OutputStr
    mov  eax, 2
    jmp  rr_ok
rr_end:
    mov  eax, 1
rr_ok:
    add  rsp, 28h
    pop  rsi
    pop  rbx
    ret
ReadRealValue ENDP

; --- Print branch description ---
PrintBranchDesc PROC
    sub  rsp, 28h
    lea  rdx, T_BR1
    cmp  ecx, 2
    jne  pb3
    lea  rdx, T_BR2
pb3:
    cmp  ecx, 3
    jne  pbprint
    lea  rdx, T_BR3
pbprint:
    mov  rcx, rdx
    call OutputStr
    add  rsp, 28h
    ret
PrintBranchDesc ENDP

; ===========================================================================
; PART 1: Integer FPU instructions
; ===========================================================================

; Branch 1: f = 2xy + 3
IntBranch1 PROC
    fild  dword ptr [rcx]
    fimul dword ptr [rdx]
    fimul dword ptr [C_2]
    fiadd dword ptr [C_3]
    fistp dword ptr [r8]
    xor  eax, eax
    ret
IntBranch1 ENDP

; Branch 2: f = 3y^2 / (x^2 + 2y + 1)
IntBranch2 PROC
    sub  rsp, 28h
    fild  dword ptr [rdx]
    fimul dword ptr [rdx]
    fimul dword ptr [C_3]
    fild  dword ptr [rcx]
    fimul dword ptr [rcx]
    fild  dword ptr [rdx]
    fimul dword ptr [C_2]
    faddp st(1), st(0)
    fiadd dword ptr [C_1]
    fistp dword ptr [rsp + 20h]
    cmp  dword ptr [rsp + 20h], 0
    je   ib2_zero
    fidiv dword ptr [rsp + 20h]
    fistp dword ptr [r8]
    xor  eax, eax
    jmp  ib2_exit
ib2_zero:
    mov  eax, 1
ib2_exit:
    add  rsp, 28h
    ret
IntBranch2 ENDP

; Branch 3: f = 2x^2 - 2y + 1
IntBranch3 PROC
    fild  dword ptr [rcx]
    fimul dword ptr [rcx]
    fimul dword ptr [C_2]
    fild  dword ptr [rdx]
    fimul dword ptr [C_2]
    fsubp st(1), st(0)
    fiadd dword ptr [C_1]
    fistp dword ptr [r8]
    xor  eax, eax
    ret
IntBranch3 ENDP

; --- Branch selector for integers ---
IntCalc PROC
    sub  rsp, 28h
    fild  dword ptr [rcx]
    fisub dword ptr [rdx]
    fild  dword ptr [C_9]
    fcomip st(0), st(1)
    jb   ic_b1
    fild  dword ptr [C_M6]
    fcomip st(0), st(1)
    ja   ic_b2
    fstp st(0)
    call IntBranch3
    mov  edx, 3
    jmp  ic_exit
ic_b1:
    fstp st(0)
    call IntBranch1
    mov  edx, 1
    jmp  ic_exit
ic_b2:
    fstp st(0)
    call IntBranch2
    mov  edx, 2
ic_exit:
    add  rsp, 28h
    ret
IntCalc ENDP

; ===========================================================================
; PART 2: Real FPU instructions
; ===========================================================================

; Branch 1: f = 2xy + 3
RealBranch1 PROC
    fld  qword ptr [rcx]
    fmul qword ptr [rdx]
    fmul qword ptr [R_2]
    fld  qword ptr [R_3]
    faddp st(1), st(0)
    fstp qword ptr [r8]
    xor  eax, eax
    ret
RealBranch1 ENDP

; Branch 2: f = 3y^2 / (x^2 + 2y + 1)
RealBranch2 PROC
    fld  qword ptr [rdx]
    fmul qword ptr [rdx]
    fmul qword ptr [R_3]
    fld  qword ptr [rcx]
    fmul qword ptr [rcx]
    fld  qword ptr [rdx]
    fmul qword ptr [R_2]
    faddp st(1), st(0)
    fld1
    faddp st(1), st(0)
    fldz
    fcomip st(0), st(1)
    je   rb2_zero
    fdivp st(1), st(0)
    fstp qword ptr [r8]
    xor  eax, eax
    ret
rb2_zero:
    fstp st(0)
    fstp st(0)
    mov  eax, 1
    ret
RealBranch2 ENDP

; Branch 3: f = 2x^2 - 2y + 1
RealBranch3 PROC
    fld  qword ptr [rcx]
    fmul qword ptr [rcx]
    fmul qword ptr [R_2]
    fld  qword ptr [rdx]
    fmul qword ptr [R_2]
    fsubp st(1), st(0)
    fld1
    faddp st(1), st(0)
    fstp qword ptr [r8]
    xor  eax, eax
    ret
RealBranch3 ENDP

; --- Branch selector for reals ---
RealCalc PROC
    sub  rsp, 28h
    fld  qword ptr [rcx]
    fsub qword ptr [rdx]
    fld  qword ptr [R_9]
    fcomip st(0), st(1)
    jb   rc_b1
    fld  qword ptr [R_M6]
    fcomip st(0), st(1)
    ja   rc_b2
    fstp st(0)
    call RealBranch3
    mov  edx, 3
    jmp  rc_exit
rc_b1:
    fstp st(0)
    call RealBranch1
    mov  edx, 1
    jmp  rc_exit
rc_b2:
    fstp st(0)
    call RealBranch2
    mov  edx, 2
rc_exit:
    add  rsp, 28h
    ret
RealCalc ENDP

; --- Run integer part ---
RunIntSection PROC
    sub  rsp, 158h
    lea  rcx, T_PART1
    call OutputStr
ri_loop:
    lea  rcx, T_X
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 120h]
    call ReadIntValue
    cmp  eax, 1
    je   ri_done
    test eax, eax
    jnz  ri_loop
    lea  rcx, T_Y
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 124h]
    call ReadIntValue
    cmp  eax, 1
    je   ri_done
    test eax, eax
    jnz  ri_loop
    lea  rcx, [rsp + 120h]
    lea  rdx, [rsp + 124h]
    lea  r8, [rsp + 128h]
    call IntCalc
    mov  dword ptr [rsp + 12Ch], eax
    mov  ecx, edx
    call PrintBranchDesc
    cmp  dword ptr [rsp + 12Ch], 0
    jne  ri_err
    lea  rcx, [rsp + 130h]
    mov  edx, dword ptr [rsp + 128h]
    call SIntToStr
    lea  rcx, T_RES
    call OutputStr
    lea  rcx, [rsp + 130h]
    call OutputStr
    lea  rcx, T_NL
    call OutputStr
    jmp  ri_loop
ri_err:
    lea  rcx, T_DIV0
    call OutputStr
    jmp  ri_loop
ri_done:
    add  rsp, 158h
    ret
RunIntSection ENDP

; --- Run real part ---
RunRealSection PROC
    sub  rsp, 168h
    lea  rcx, T_PART2
    call OutputStr
rr_loop:
    lea  rcx, T_X
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 120h]
    call ReadRealValue
    cmp  eax, 1
    je   rr_done
    test eax, eax
    jnz  rr_loop
    lea  rcx, T_Y
    lea  rdx, [rsp + 20h]
    lea  r8, [rsp + 128h]
    call ReadRealValue
    cmp  eax, 1
    je   rr_done
    test eax, eax
    jnz  rr_loop
    lea  rcx, [rsp + 120h]
    lea  rdx, [rsp + 128h]
    lea  r8, [rsp + 130h]
    call RealCalc
    mov  dword ptr [rsp + 138h], eax
    mov  ecx, edx
    call PrintBranchDesc
    cmp  dword ptr [rsp + 138h], 0
    jne  rr_err
    lea  rcx, [rsp + 140h]
    lea  rdx, [rsp + 130h]
    call RealToStr
    lea  rcx, T_RES
    call OutputStr
    lea  rcx, [rsp + 140h]
    call OutputStr
    lea  rcx, T_NL
    call OutputStr
    jmp  rr_loop
rr_err:
    lea  rcx, T_DIV0
    call OutputStr
    jmp  rr_loop
rr_done:
    add  rsp, 168h
    ret
RunRealSection ENDP

; --- Entry point ---
main PROC
    sub  rsp, 28h
    lea  rcx, T_TITLE
    call OutputStr
    lea  rcx, T_TASK
    call OutputStr
    call RunIntSection
    call RunRealSection
    lea  rcx, T_END
    call OutputStr
    xor  ecx, ecx
    call ExitProcess
main ENDP

END