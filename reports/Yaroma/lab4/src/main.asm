; Lab 4, variant 12: both sections of the x87 assignment, pages 316-318.
.686
.model flat, stdcall
option casemap:none
include numeric_io.inc
SetConsoleCP PROTO :DWORD
SetConsoleOutputCP PROTO :DWORD
exit PROTO C :SDWORD
.const
header BYTE 'АПО ЭВМиС. Лабораторная работа №4',13,10
       BYTE 'Ярома А. И. | АС-66 | Вариант 12 | MASM x86 / x87',13,10
       BYTE '1 - целочисленные команды; 2 - вещественные команды.',13,10
       BYTE 'Каждое число вводите на отдельной строке. Дробная часть: через точку.',13,10
       BYTE 'Выберите раздел (1/2): ',0
promptX BYTE 'Введите x: ',0
promptY BYTE 'Введите y: ',0
intValues BYTE 13,10,'Раздел 1: целочисленные команды x87.',13,10
          BYTE 'x = %d; y = %d',13,10,0
realValues BYTE 13,10,'Раздел 2: вещественные команды x87.',13,10
           BYTE 'x = %.17g; y = %.17g',13,10,0
branchOne BYTE 'Ветвь 1: x - y > 2; r = (x*x - 4*y + 5) / (x*x + 2)',13,10,0
branchTwo BYTE 'Ветвь 2: x - y < -4; r = (2*x + y) / (3*x*x + 4)',13,10,0
branchThree BYTE 'Ветвь 3: -4 <= x - y <= 2; r = x*x - 2*y + 3',13,10,0
resultFormat BYTE 'Результат: %.17g',13,10,0
inputError BYTE 13,10,'Ошибка: некорректное число, диапазон или раздел.',13,10
           BYTE 'Целые: -2147483648..2147483647. Вещественные: конечные double.',13,10,0
numericError BYTE 'Ошибка: результат не представим конечным double.',13,10,0
.code
ProgramMain PROC
    LOCAL mode:DWORD, xInt:SDWORD, yInt:SDWORD
    LOCAL xReal:REAL8, yReal:REAL8, result:REAL8, branch:DWORD
    invoke SetConsoleCP, 65001
    invoke SetConsoleOutputCP, 65001
    invoke printf, ADDR header
    invoke ReadNumber, 1, ADDR mode
    test eax, eax
    jnz input_bad
    cmp mode, 1
    je integer_input
    cmp mode, 2
    jne input_bad
    invoke printf, ADDR promptX
    invoke ReadNumber, 2, ADDR xReal
    test eax, eax
    jnz input_bad
    invoke printf, ADDR promptY
    invoke ReadNumber, 2, ADDR yReal
    test eax, eax
    jnz input_bad
    invoke printf, ADDR realValues, xReal, yReal
    invoke EvaluateReal, ADDR xReal, ADDR yReal, ADDR result, ADDR branch
    jmp checked
integer_input:
    invoke printf, ADDR promptX
    invoke ReadNumber, 1, ADDR xInt
    test eax, eax
    jnz input_bad
    invoke printf, ADDR promptY
    invoke ReadNumber, 1, ADDR yInt
    test eax, eax
    jnz input_bad
    invoke printf, ADDR intValues, xInt, yInt
    invoke EvaluateInteger, xInt, yInt, ADDR result, ADDR branch
checked:
    test eax, eax
    jnz numeric_bad
    cmp branch, 1
    je print_one
    cmp branch, 2
    je print_two
    invoke printf, ADDR branchThree
    jmp print_result
print_one:
    invoke printf, ADDR branchOne
    jmp print_result
print_two:
    invoke printf, ADDR branchTwo
print_result:
    invoke printf, ADDR resultFormat, result
    xor eax, eax
    ret
input_bad:
    invoke printf, ADDR inputError
    mov eax, 1
    ret
numeric_bad:
    invoke printf, ADDR numericError
    mov eax, 1
    ret
ProgramMain ENDP
start:
    finit
    invoke ProgramMain
    invoke exit, eax
END start
