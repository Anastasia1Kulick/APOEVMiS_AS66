; Лабораторная работа 4 (ЛР №1 по сопроцессору), вариант 15
; Раздел 1 - целочисленные команды сопроцессора
; Раздел 2 - вещественные команды сопроцессора
;
; Функция:
;        | 5xy - 3,            x + y > 8
;    y = | 4xy^2 / (x^2 + 1),  x + y < -5
;        | 2x^2 - 4y^2 + 3,    -5 <= x + y <= 8
;
; Каждая ветка оформлена отдельной внутренней процедурой.
; Результат функции возвращается в ST(0) (так C++ забирает double),
; номер сработавшей ветки пишется по указателю pBranch.
.686
.model flat, c
option casemap:none

.data
; переменные для раздела 1 (целые)
xi   DD ?
yi   DD ?
; константы для целочисленных команд
i1   DD 1
i2   DD 2
i3   DD 3
i4   DD 4
i5   DD 5
i8   DD 8
im5  DD -5

; переменные для раздела 2 (вещественные)
xr   DQ ?
yr   DQ ?
; вещественные константы
r1   DQ 1.0
r2   DQ 2.0
r3   DQ 3.0
r4   DQ 4.0
r5   DQ 5.0
r8   DQ 8.0
rm5  DQ -5.0

.code

; ======================= РАЗДЕЛ 1: целочисленные команды =======================

; Ветка 1: 5xy - 3   (результат в ST(0))
Branch1Int PROC
    fild  xi                  ; st0 = x
    fimul yi                  ; st0 = x*y
    fimul i5                  ; st0 = 5xy
    fisub i3                  ; st0 = 5xy - 3
    ret
Branch1Int ENDP

; Ветка 2: 4xy^2 / (x^2 + 1)
Branch2Int PROC
    fild  xi                  ; st0 = x
    fimul yi                  ; st0 = xy
    fimul yi                  ; st0 = xy^2
    fimul i4                  ; st0 = 4xy^2 (числитель)
    fild  xi                  ; st0 = x, st1 = числитель
    fimul xi                  ; st0 = x^2
    fiadd i1                  ; st0 = x^2 + 1 (знаменатель)
    fdivp st(1), st           ; st1 = st1 / st0, вершина выталкивается
    ret                       ; st0 = 4xy^2 / (x^2 + 1)
Branch2Int ENDP

; Ветка 3: 2x^2 - 4y^2 + 3
Branch3Int PROC
    fild  xi                  ; st0 = x
    fimul xi                  ; st0 = x^2
    fimul i2                  ; st0 = 2x^2
    fild  yi                  ; st0 = y, st1 = 2x^2
    fimul yi                  ; st0 = y^2
    fimul i4                  ; st0 = 4y^2
    fsubp st(1), st           ; st1 = 2x^2 - 4y^2, вершина выталкивается
    fiadd i3                  ; st0 = 2x^2 - 4y^2 + 3
    ret
Branch3Int ENDP

; double CalcInt(int x, int y, int* pBranch)
CalcInt PROC x:DWORD, y:DWORD, pBranch:DWORD
    mov  eax, x               ; кладём параметры в переменные,
    mov  xi, eax              ; с ними работают внутренние процедуры
    mov  eax, y
    mov  yi, eax

    finit                     ; приводим сопроцессор в начальное состояние
    fild  xi                  ; st0 = x
    fiadd yi                  ; st0 = x + y

    ficom i8                  ; сравниваем x + y с 8
    fstsw ax                  ; SWR -> AX
    sahf                      ; AX -> флаги (C0 -> CF, C3 -> ZF)
    ja   int_case1            ; x + y > 8

    ficomp im5                ; сравниваем x + y с -5 и выталкиваем сумму
    fstsw ax
    sahf
    jb   int_case2            ; x + y < -5

    call Branch3Int           ; иначе -5 <= x + y <= 8
    mov  edx, 3
    jmp  int_done

int_case1:
    fstp st(0)                ; сумма больше не нужна, убираем её из стека
    call Branch1Int
    mov  edx, 1
    jmp  int_done

int_case2:
    call Branch2Int
    mov  edx, 2

int_done:
    mov  ecx, pBranch         ; сообщаем, какая ветка сработала
    mov  [ecx], edx
    ret                       ; результат остаётся в ST(0)
CalcInt ENDP

; ======================= РАЗДЕЛ 2: вещественные команды =======================

; Ветка 1: 5xy - 3
Branch1Real PROC
    fld  xr                   ; st0 = x
    fmul yr                   ; st0 = xy
    fmul r5                   ; st0 = 5xy
    fsub r3                   ; st0 = 5xy - 3
    ret
Branch1Real ENDP

; Ветка 2: 4xy^2 / (x^2 + 1)
Branch2Real PROC
    fld  xr                   ; st0 = x
    fmul st(0), st(0)              ; st0 = x^2
    fadd r1                   ; st0 = x^2 + 1 (знаменатель)
    fld  yr                   ; st0 = y, st1 = знаменатель
    fmul st(0), st(0)              ; st0 = y^2
    fmul xr                   ; st0 = xy^2
    fmul r4                   ; st0 = 4xy^2 (числитель)
    fdivrp st(1), st          ; st1 = st0 / st1, вершина выталкивается
    ret                       ; st0 = 4xy^2 / (x^2 + 1)
Branch2Real ENDP

; Ветка 3: 2x^2 - 4y^2 + 3
Branch3Real PROC
    fld  xr                   ; st0 = x
    fmul st(0), st(0)              ; st0 = x^2
    fmul r2                   ; st0 = 2x^2
    fld  yr                   ; st0 = y, st1 = 2x^2
    fmul st(0), st(0)              ; st0 = y^2
    fmul r4                   ; st0 = 4y^2
    fsubp st(1), st           ; st1 = 2x^2 - 4y^2, вершина выталкивается
    fadd r3                   ; st0 = 2x^2 - 4y^2 + 3
    ret
Branch3Real ENDP

; double CalcReal(double x, double y, int* pBranch)
CalcReal PROC x:QWORD, y:QWORD, pBranch:DWORD
    finit
    fld  x                    ; копируем параметры в переменные
    fstp xr
    fld  y
    fstp yr

    fld  xr                   ; st0 = x
    fadd yr                   ; st0 = x + y

    fcom r8                   ; сравниваем x + y с 8.0
    fstsw ax
    sahf
    ja   real_case1           ; x + y > 8

    fcomp rm5                 ; сравниваем x + y с -5.0 и выталкиваем сумму
    fstsw ax
    sahf
    jb   real_case2           ; x + y < -5

    call Branch3Real          ; иначе -5 <= x + y <= 8
    mov  edx, 3
    jmp  real_done

real_case1:
    fstp st(0)
    call Branch1Real
    mov  edx, 1
    jmp  real_done

real_case2:
    call Branch2Real
    mov  edx, 2

real_done:
    mov  ecx, pBranch
    mov  [ecx], edx
    ret                       ; результат в ST(0)
CalcReal ENDP

END
