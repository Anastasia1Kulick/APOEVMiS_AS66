; lab4_real.asm
; Лаб. №1 (сопроцессор), Раздел 2: вещественные команды. Вариант 1.
;
; y = 6xy - 4y,                          x + y > 9
;   = (2xy + 3 + x) / (x^2 + 3y^2 + 1),  x + y < -1
;   = 3x^2 - 2y + 6,                     -1 <= x + y <= 9
;
; extern "C" double ComputeRealAsm(double x, double y);
; x, y - вещественные числа; вычисление идёт через "чистые"
; вещественные команды сопроцессора (FLD/FADD/FSUB/FMUL/FDIV,
; без буквы I - операнды уже в формате с плавающей точкой).

.386
.387
.MODEL FLAT, C
OPTION PROC:PRIVATE

.DATA
const_1 REAL8 1.0
const_2 REAL8 2.0
const_3 REAL8 3.0
const_4 REAL8 4.0
const_6 REAL8 6.0
const_9    REAL8 9.0
const_neg1 REAL8 -1.0

.CODE

; ---------------------------------------------------------------
; Branch1: x + y > 9  =>  y = 6xy - 4y = y*(6x - 4)
; double-параметры в cdecl занимают по 8 байт: x -> [ebp+8], y -> [ebp+16]
; ---------------------------------------------------------------
Branch1 PROC
    fld qword ptr [ebp+8]        ; ST0 = x
    fmul const_6                   ; ST0 = 6x
    fsub const_4                    ; ST0 = 6x - 4
    fmul qword ptr [ebp+16]          ; ST0 = (6x-4)*y = 6xy - 4y
    ret
Branch1 ENDP

; ---------------------------------------------------------------
; Branch2: x + y < -1  =>  y = (2xy+3+x) / (x^2+3y^2+1)
;          числитель переписан как x*(2y+1)+3
; ---------------------------------------------------------------
Branch2 PROC
    ; числитель
    fld qword ptr [ebp+16]         ; ST0 = y
    fmul const_2                     ; ST0 = 2y
    fadd const_1                      ; ST0 = 2y + 1
    fmul qword ptr [ebp+8]             ; ST0 = x*(2y+1)
    fadd const_3                        ; ST0 = числитель

    ; знаменатель
    fld qword ptr [ebp+8]                ; ST0 = x,              ST1 = числитель
    fmul qword ptr [ebp+8]               ; ST0 = x^2,            ST1 = числитель
    fld qword ptr [ebp+16]                ; ST0 = y,   ST1 = x^2, ST2 = числитель
    fmul qword ptr [ebp+16]               ; ST0 = y^2, ST1 = x^2, ST2 = числитель
    fmul const_3                           ; ST0 = 3y^2, ST1 = x^2, ST2 = числитель
    faddp st(1), st(0)                      ; ST0 = x^2+3y^2,       ST1 = числитель
    fadd const_1                             ; ST0 = знаменатель,    ST1 = числитель

    fdivp st(1), st(0)                        ; ST0 = числитель / знаменатель
    ret
Branch2 ENDP

; ---------------------------------------------------------------
; Branch3: -1 <= x + y <= 9  =>  y = 3x^2 - 2y + 6
; ---------------------------------------------------------------
Branch3 PROC
    fld qword ptr [ebp+8]        ; ST0 = x
    fmul qword ptr [ebp+8]        ; ST0 = x^2
    fmul const_3                   ; ST0 = 3x^2

    fld qword ptr [ebp+16]          ; ST0 = y,    ST1 = 3x^2
    fmul const_2                     ; ST0 = 2y,   ST1 = 3x^2

    fsubp st(1), st(0)                ; ST0 = 3x^2 - 2y
    fadd const_6                       ; ST0 = 3x^2 - 2y + 6
    ret
Branch3 ENDP

; ---------------------------------------------------------------
; double ComputeRealAsm(double x, double y)
; Диспетчер: x,y вещественные, поэтому сравнение x+y с границами
; идёт через сам сопроцессор (fcomp), а не через обычный cmp.
; ---------------------------------------------------------------
PUBLIC ComputeRealAsm
ComputeRealAsm PROC
    push ebp
    mov  ebp, esp

    ; Первая проверка: x + y > 9 ?
    fld qword ptr [ebp+8]          ; ST0 = x
    fadd qword ptr [ebp+16]         ; ST0 = x + y
    fcomp const_9                    ; сравнить ST0 с 9.0, вытолкнуть ST0 (стек снова пуст)
    fnstsw ax                         ; перенести статус-слово FPU в AX
    sahf                                ; AH -> флаги процессора, теперь работают обычные Jcc
    ja  DoBranch1                        ; x+y > 9

    ; Вторая проверка: x + y < -1 ?
    fld qword ptr [ebp+8]            ; пересчитываем сумму заново - стек FPU уже чист после fcomp
    fadd qword ptr [ebp+16]
    fcomp const_neg1
    fnstsw ax
    sahf
    jb  DoBranch2                       ; x+y < -1

    call Branch3                          ; иначе: -1 <= x+y <= 9
    jmp ComputeDone

DoBranch1:
    call Branch1
    jmp ComputeDone

DoBranch2:
    call Branch2

ComputeDone:
    pop ebp
    ret
ComputeRealAsm ENDP

END