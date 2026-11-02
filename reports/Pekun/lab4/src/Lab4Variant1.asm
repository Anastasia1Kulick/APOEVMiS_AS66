.686
.model flat, c
option casemap:none
includelib msvcrt.lib
includelib kernel32.lib
printf PROTO C :PTR BYTE, :VARARG
scanf PROTO C :PTR BYTE, :VARARG
ExitProcess PROTO STDCALL :DWORD
GetStdHandle PROTO STDCALL :DWORD
GetConsoleMode PROTO STDCALL :DWORD, :DWORD
getchar PROTO C
.data
intro BYTE "Lab 4, variant 1. x87 coprocessor",13,10,"1 - integer operands, 2 - real operands",13,10,"Mode: ",0
prompt BYTE "Enter x and y: ",0
formatMode BYTE "%d",0
formatInts BYTE "%d %d",0
formatReals BYTE "%lf %lf",0
formatOut BYTE "Result: %.8f",13,10,0
err BYTE "Invalid input.",13,10,0
exitMsg BYTE "Press Enter to close.",13,10,0
consoleMode DWORD 0
mode DWORD 0
ix SDWORD 0
iy SDWORD 0
rx REAL8 0.0
ry REAL8 0.0
result REAL8 0.0
numerator REAL8 0.0
denominator REAL8 0.0
six SDWORD 6
four SDWORD 4
three SDWORD 3
two SDWORD 2
rsix REAL8 6.0
rfour REAL8 4.0
rthree REAL8 3.0
rtwo REAL8 2.0
minusOne REAL8 -1.0
nine REAL8 9.0
.code
IntegerHigh PROC
 fild ix
 fimul iy
 fimul six
 fild iy
 fimul four
 fsubp st(1), st(0)
 fstp result
 ret
IntegerHigh ENDP
IntegerLow PROC
 fild ix
 fimul iy
 fimul two
 fiadd three
 fiadd ix
 fstp numerator
 fild ix
 fimul ix
 fild iy
 fimul iy
 fimul three
 faddp st(1), st(0)
 fld1
 faddp st(1), st(0)
 fstp denominator
 fld numerator
 fdiv denominator
 fstp result
 ret
IntegerLow ENDP
IntegerMiddle PROC
 fild ix
 fimul ix
 fimul three
 fild iy
 fimul two
 fsubp st(1), st(0)
 fiadd six
 fstp result
 ret
IntegerMiddle ENDP
CalculateInteger PROC
 mov eax, ix
 cdq
 mov ecx, iy
 mov ebx, ecx
 sar ebx, 31
 add eax, ecx
 adc edx, ebx
 cmp edx, 0
 jg intHigh
 jl intNegative
 cmp eax, 9
 ja intHigh
 jmp intMiddle
intNegative:
 cmp edx, -1
 jl intLow
 cmp eax, -1
 jb intLow
intMiddle:
 call IntegerMiddle
 ret
intHigh:
 call IntegerHigh
 ret
intLow:
 call IntegerLow
 ret
CalculateInteger ENDP
RealHigh PROC
 fld rx
 fmul ry
 fmul rsix
 fld ry
 fmul rfour
 fsubp st(1), st(0)
 fstp result
 ret
RealHigh ENDP
RealLow PROC
 fld rx
 fmul ry
 fmul rtwo
 fadd rthree
 fadd rx
 fstp numerator
 fld rx
 fmul rx
 fld ry
 fmul ry
 fmul rthree
 faddp st(1), st(0)
 fld1
 faddp st(1), st(0)
 fstp denominator
 fld numerator
 fdiv denominator
 fstp result
 ret
RealLow ENDP
RealMiddle PROC
 fld rx
 fmul rx
 fmul rthree
 fld ry
 fmul rtwo
 fsubp st(1), st(0)
 fadd rsix
 fstp result
 ret
RealMiddle ENDP
CalculateReal PROC
 fld rx
 fadd ry
 fcom nine
 fnstsw ax
 sahf
 jp realInvalid
 ja realHigh
 fcom minusOne
 fnstsw ax
 sahf
 jb realLow
 fstp st(0)
 call RealMiddle
 xor eax,eax
 ret
realHigh:
 fstp st(0)
 call RealHigh
 xor eax,eax
 ret
realLow:
 fstp st(0)
 call RealLow
 xor eax,eax
 ret
realInvalid:
 fstp st(0)
 mov eax,1
 ret
CalculateReal ENDP
WaitForExit PROC
 invoke GetStdHandle, -10
 invoke GetConsoleMode, eax, ADDR consoleMode
 test eax,eax
 jz waitDone
 invoke printf, ADDR exitMsg
drainLine:
 invoke getchar
 cmp eax,-1
 je waitDone
 cmp eax,10
 jne drainLine
 invoke getchar
waitDone:
 ret
WaitForExit ENDP
main PROC
 invoke printf, ADDR intro
 invoke scanf, ADDR formatMode, ADDR mode
 cmp eax,1
 jne invalid
 cmp mode,1
 je readInteger
 cmp mode,2
 jne invalid
 invoke printf, ADDR prompt
 invoke scanf, ADDR formatReals, ADDR rx, ADDR ry
 cmp eax,2
 jne invalid
 call CalculateReal
 test eax,eax
 jnz invalid
 jmp showResult
readInteger:
 invoke printf, ADDR prompt
 invoke scanf, ADDR formatInts, ADDR ix, ADDR iy
 cmp eax,2
 jne invalid
 call CalculateInteger
showResult:
 invoke printf, ADDR formatOut, DWORD PTR result, DWORD PTR result+4
 call WaitForExit
 invoke ExitProcess, 0
invalid:
 invoke printf, ADDR err
 call WaitForExit
 invoke ExitProcess, 1
main ENDP
END main
