// Apple Silicon adaptation, same C ABI and UTF-32 representation.
.text
.p2align 2
.globl _check_condition
_check_condition:
    mov x2, #0
    mov x3, #0
    cbz x1, 4f
1:  ldr w4, [x0], #4
    sub w5, w4, #65
    cmp w5, #25
    b.hi 2f
    add x2, x2, #1
    b 3f
2:  cmp w4, #0x401
    b.eq 5f
    sub w5, w4, #0x410
    cmp w5, #31
    b.hi 3f
5:  add x3, x3, #1
3:  subs x1, x1, #1
    b.ne 1b
4:  cmp x2, x3
    cset w0, eq
    ret
.p2align 2
.globl _transform_text
_transform_text:
    cbz x1, 4f
1:  ldr w2, [x0]
    sub w3, w2, #65
    cmp w3, #25
    b.ls 2f
    sub w3, w2, #97
    cmp w3, #25
    b.hi 3f
2:  eor w2, w2, #0x20
    str w2, [x0]
3:  add x0, x0, #4
    subs x1, x1, #1
    b.ne 1b
4:  ret
