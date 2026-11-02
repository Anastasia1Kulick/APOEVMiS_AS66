# macOS x86-64 SysV ABI: int x/y in edi/esi, result double in xmm0.
# Preconditions: -1000 <= x,y <= 1000. Every branch leaves one x87 value.
.text
.globl _integer
_integer:
    pushq %rbp
    movq %rsp, %rbp
    subq $48, %rsp
    movl %edi, -4(%rbp)
    movl %esi, -8(%rbp)
    movl $1, -12(%rbp)
    movl $2, -16(%rbp)
    movl $3, -20(%rbp)
    movl $4, -24(%rbp)
    movl $5, -28(%rbp)
    leal (%rdi,%rsi), %eax
    cmpl $9, %eax
    jg Lint_high_call
    cmpl $-5, %eax
    jl Lint_low_call
    call Lint_middle
    jmp Lint_return
Lint_high_call:
    call Lint_high
    jmp Lint_return
Lint_low_call:
    call Lint_low
Lint_return:
    fstpl -48(%rbp)       # pop; SysV returns double in xmm0, not st(0)
    movsd -48(%rbp), %xmm0
    leave
    ret

# Internal procedures use the parent's rbp frame and return a single st(0).
Lint_high:                # 5*x + 2*x*y + 1
    fildl -4(%rbp)
    fimull -8(%rbp)
    fimull -16(%rbp)
    fistpl -32(%rbp)
    fildl -4(%rbp)
    fimull -28(%rbp)
    fiaddl -32(%rbp)
    fiaddl -12(%rbp)
    ret
Lint_low:                 # (2*x*y + 3)/(y*y + 4)
    fildl -8(%rbp)
    fimull -8(%rbp)
    fiaddl -24(%rbp)
    fistpl -32(%rbp)
    fildl -4(%rbp)
    fimull -8(%rbp)
    fimull -16(%rbp)
    fiaddl -20(%rbp)
    fidivl -32(%rbp)
    ret
Lint_middle:              # 3*x*x - 2*y*y + 1
    fildl -8(%rbp)
    fimull -8(%rbp)
    fimull -16(%rbp)
    fistpl -32(%rbp)
    fildl -4(%rbp)
    fimull -4(%rbp)
    fimull -20(%rbp)
    fisubl -32(%rbp)
    fiaddl -12(%rbp)
    ret

# double x/y in xmm0/xmm1. Compare the EXACT sum of the two input doubles.
# Assumes the usual ABI environment: round-to-nearest, gradual underflow,
# and SSE DAZ/FTZ disabled; see README for the TwoSum proof.
.globl _real
_real:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp
    movsd %xmm0, -8(%rbp)
    movsd %xmm1, -16(%rbp)
    addsd %xmm1, %xmm0          # s = round(x + y)
    comisd Lnine(%rip), %xmm0
    ja Lreal_high_call
    je Lreal_tie_high
    comisd Lminusfive(%rip), %xmm0
    jb Lreal_low_call
    je Lreal_tie_low
Lreal_middle_call:
    call Lreal_middle
    jmp Lreal_return
Lreal_tie_high:
    movl $1, %eax              # rounded sum was 9
    jmp Lreal_residual
Lreal_tie_low:
    xorl %eax, %eax            # rounded sum was -5
Lreal_residual:
    # Knuth TwoSum: b_virtual = s-x, a_virtual = s-b_virtual;
    # residual = (x-a_virtual) + (y-b_virtual), exactly x+y-s.
    # Do not replace with long double: even 80 bits lose DBL_TRUE_MIN at 9.
    movapd %xmm0, %xmm2
    subsd -8(%rbp), %xmm2      # b_virtual
    movapd %xmm0, %xmm3
    subsd %xmm2, %xmm3         # a_virtual
    movsd -8(%rbp), %xmm4
    subsd %xmm3, %xmm4         # x-a_virtual
    subsd %xmm2, %xmm1         # y-b_virtual
    addsd %xmm1, %xmm4         # exact residual (including subnormals)
    pxor %xmm5, %xmm5
    testl %eax, %eax
    jz Lreal_residual_low
    comisd %xmm5, %xmm4
    ja Lreal_high_call          # 9 + positive error > 9
    jmp Lreal_middle_call
Lreal_residual_low:
    comisd %xmm5, %xmm4
    jb Lreal_low_call           # -5 + negative error < -5
    jmp Lreal_middle_call
Lreal_high_call:
    call Lreal_high
    jmp Lreal_return
Lreal_low_call:
    call Lreal_low
Lreal_return:
    fstpl -24(%rbp)
    movsd -24(%rbp), %xmm0
    leave
    ret
Lreal_high:              # 5*x + 2*x*y + 1
    fldl -8(%rbp)
    fmull -16(%rbp)
    fmull Ltwo(%rip)
    fstpl -24(%rbp)
    fldl -8(%rbp)
    fmull Lfive(%rip)
    faddl -24(%rbp)
    faddl Lone(%rip)
    ret
Lreal_low:               # (2*x*y + 3)/(y*y + 4)
    fldl -16(%rbp)
    fmull -16(%rbp)
    faddl Lfour(%rip)
    fstpl -24(%rbp)
    fldl -8(%rbp)
    fmull -16(%rbp)
    fmull Ltwo(%rip)
    faddl Lthree(%rip)
    fdivl -24(%rbp)
    ret
Lreal_middle:            # 3*x*x - 2*y*y + 1
    fldl -16(%rbp)
    fmull -16(%rbp)
    fmull Ltwo(%rip)
    fstpl -24(%rbp)
    fldl -8(%rbp)
    fmull -8(%rbp)
    fmull Lthree(%rip)
    fsubl -24(%rbp)
    faddl Lone(%rip)
    ret

.section __TEXT,__const
.p2align 3
Lone:       .double 1.0
Ltwo:       .double 2.0
Lthree:     .double 3.0
Lfour:      .double 4.0
Lfive:      .double 5.0
Lnine:      .double 9.0
Lminusfive: .double -5.0
