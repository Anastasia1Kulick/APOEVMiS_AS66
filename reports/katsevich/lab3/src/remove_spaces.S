// Apple Silicon / AArch64, соглашение вызовов Darwin arm64.
// Макроопределение, а не функция: ассемблер вставляет тело в каждое место вызова.
// Вход: x0 = адрес изменяемого массива байтов, x1 = его длина.
// Выход: x0 = новая длина. Рабочие регистры: x2, x3, w4.
// Удаляется только байт ASCII-пробела 0x20. Завершающий NUL не записывается.
.macro REMOVE_SPACES
    mov x2, #0                  // позиция чтения
    mov x3, #0                  // позиция записи
1:
    cmp x2, x1
    b.hs 3f
    ldrb w4, [x0, x2]
    add x2, x2, #1
    cmp w4, #0x20
    b.eq 1b
    strb w4, [x0, x3]
    add x3, x3, #1
    b 1b
3:
    mov x0, x3
.endm

.text
.p2align 2
.globl _remove_spaces
_remove_spaces:
    REMOVE_SPACES              // первое расширение макроса
    ret

.p2align 2
.globl _remove_spaces_second
_remove_spaces_second:
    REMOVE_SPACES              // независимое второе расширение
    ret
