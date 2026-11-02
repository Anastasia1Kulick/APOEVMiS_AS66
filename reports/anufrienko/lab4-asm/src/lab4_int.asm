; lab4_int.asm
; Лаб. №1 (сопроцессор), Раздел 1: целочисленные команды. Вариант 1.
;
; y = 6xy - 4y,                          x + y > 9
;   = (2xy + 3 + x) / (x^2 + 3y^2 + 1),  x + y < -1
;   = 3x^2 - 2y + 6,                     -1 <= x + y <= 9
;
; extern "C" double ComputeIntAsm(int x, int y);
; x, y - целые числа; вычисление идёт через целочисленные команды
; сопроцессора (FILD/FIADD/FISUB/FIMUL - работают прямо с целым
; числом в памяти, без предварительного перевода в вещественный формат).

.386
.387
.MODEL FLAT, C
OPTION PROC:PRIVATE

.DATA
const_1 DWORD 1
const_2 DWORD 2
const_3 DWORD 3
const_4 DWORD 4
const_6 DWORD 6

.CODE

; ---------------------------------------------------------------
; Branch1: x + y > 9  =>  y = 6xy - 4y = y*(6x - 4)
; (внутренняя процедура - использует [ebp+8]/[ebp+12] того кадра
;  стека, что уже подготовлен вызывающей ComputeIntAsm)
; ---------------------------------------------------------------
Branch1 PROC
    fild dword ptr [ebp+8]       ; ST0 = x
    fimul const_6                 ; ST0 = 6x
    fisub const_4                  ; ST0 = 6x - 4
    fimul dword ptr [ebp+12]        ; ST0 = (6x-4)*y = 6xy - 4y
    ret
Branch1 ENDP

; ---------------------------------------------------------------
; Branch2: x + y < -1  =>  y = (2xy+3+x) / (x^2+3y^2+1)
;          числитель переписан как x*(2y+1)+3 - алгебраически то же самое
; ---------------------------------------------------------------
Branch2 PROC
    ; числитель
    fild dword ptr [ebp+12]        ; ST0 = y
    fimul const_2                    ; ST0 = 2y
    fiadd const_1                     ; ST0 = 2y + 1
    fimul dword ptr [ebp+8]            ; ST0 = x*(2y+1)
    fiadd const_3                       ; ST0 = числитель

    ; знаменатель
    fild dword ptr [ebp+8]               ; ST0 = x,              ST1 = числитель
    fimul dword ptr [ebp+8]              ; ST0 = x^2,            ST1 = числитель
    fild dword ptr [ebp+12]               ; ST0 = y,   ST1 = x^2, ST2 = числитель
    fimul dword ptr [ebp+12]              ; ST0 = y^2, ST1 = x^2, ST2 = числитель
    fimul const_3                          ; ST0 = 3y^2, ST1 = x^2, ST2 = числитель
    faddp st(1), st(0)                      ; ST0 = x^2+3y^2,       ST1 = числитель
    fiadd const_1                            ; ST0 = знаменатель,    ST1 = числитель

    fdivp st(1), st(0)                        ; ST0 = числитель / знаменатель
    ret
Branch2 ENDP

; ---------------------------------------------------------------
; Branch3: -1 <= x + y <= 9  =>  y = 3x^2 - 2y + 6
; ---------------------------------------------------------------
Branch3 PROC
    fild dword ptr [ebp+8]       ; ST0 = x
    fimul dword ptr [ebp+8]       ; ST0 = x^2
    fimul const_3                  ; ST0 = 3x^2

    fild dword ptr [ebp+12]         ; ST0 = y,    ST1 = 3x^2
    fimul const_2                    ; ST0 = 2y,   ST1 = 3x^2

    fsubp st(1), st(0)                ; ST0 = 3x^2 - 2y
    fiadd const_6                      ; ST0 = 3x^2 - 2y + 6
    ret
Branch3 ENDP

; ---------------------------------------------------------------
; double ComputeIntAsm(int x, int y)
; Диспетчер: сравнивает x+y с границами и вызывает нужную ветку.
; Результат остаётся в ST(0) - так x87/cdecl возвращает double.
; ---------------------------------------------------------------
PUBLIC ComputeIntAsm
ComputeIntAsm PROC
    push ebp
    mov  ebp, esp

    mov eax, [ebp+8]          ; x
    add eax, [ebp+12]         ; eax = x + y (обычное целочисленное сложение, FPU тут не нужен)

    cmp eax, 9
    jg  DoBranch1               ; x+y > 9

    cmp eax, -1
    jl  DoBranch2                ; x+y < -1

    call Branch3                  ; иначе: -1 <= x+y <= 9
    jmp ComputeDone

DoBranch1:
    call Branch1
    jmp ComputeDone

DoBranch2:
    call Branch2

ComputeDone:
    pop ebp
    ret
ComputeIntAsm ENDP

END