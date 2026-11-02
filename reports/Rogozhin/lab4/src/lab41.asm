.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

ExitProcess PROTO :DWORD
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
SetConsoleCP PROTO :DWORD
SetConsoleOutputCP PROTO :DWORD

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11
MAX_LEN EQU 32

.data

promptX     db "Vvedite x: ", 0
promptY     db "Vvedite y: ", 0
branchMsg   db 13, 10, "Vibrana vetka i formula: ", 0
b1Text      db "1 (x + y > 10) ---> y = 4xy + 5", 0
b2Text      db "2 (x + y < -2) ---> y = (3xy + 2y) / (x^2 + y^2 + 1)", 0
b3Text      db "3 (-2 <= x+y <= 10)      ---> y = 6x - 2y^2 + 1", 0
resMsg      db 13, 10, "Rezultat (int): ", 0
newline     db 13, 10, 0

bufX        db MAX_LEN dup(0)
bufY        db MAX_LEN dup(0)
charsRead   dd 0

valX        dd 0
valRes      dd 0
outBuf      db 32 dup(0)

valFour     dd 4
valFive     dd 5
valThree    dd 3
valTwo      dd 2
valSix      dd 6
valOne      dd 1

.code

PrintString PROC
    push eax
    push ecx
    push edx
    push esi
    push edi

    mov esi, edx
    xor ecx, ecx
PS_Loop:
    cmp byte ptr [esi], 0
    je PS_Done
    inc esi
    inc ecx
    jmp PS_Loop
PS_Done:
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov edi, eax

    sub esp, 4
    mov eax, esp
    push 0
    push eax
    push ecx
    push edx
    push edi
    call WriteConsoleA
    add esp, 4

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
PrintString ENDP

ParseInt PROC
    push ebx
    push ecx
    push edx
    push esi

    mov esi, edx
    xor eax, eax
    xor ebx, ebx

    mov dl, byte ptr [esi]
    cmp dl, '-'
    jne PI_CheckDigit
    mov ebx, 1
    inc esi
    jmp PI_Loop

PI_CheckDigit:
    cmp dl, '+'
    jne PI_Loop
    inc esi

PI_Loop:
    mov dl, byte ptr [esi]
    cmp dl, '0'
    jb PI_Done
    cmp dl, '9'
    ja PI_Done

    sub dl, '0'
    imul eax, eax, 10
    movzx edx, dl
    add eax, edx

    inc esi
    jmp PI_Loop

PI_Done:
    cmp ebx, 1
    jne PI_Exit
    neg eax

PI_Exit:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ParseInt ENDP

IntToString PROC
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov edi, edx
    mov ecx, eax
    test ecx, ecx
    jns ITS_Positive

    mov byte ptr [edi], '-'
    inc edi
    neg ecx

ITS_Positive:
    mov eax, ecx
    mov ebx, 10
    xor ecx, ecx

ITS_PushLoop:
    xor edx, edx
    div ebx
    push edx
    inc ecx
    test eax, eax
    jnz ITS_PushLoop

ITS_PopLoop:
    pop edx
    add dl, '0'
    mov byte ptr [edi], dl
    inc edi
    dec ecx
    jnz ITS_PopLoop

    mov byte ptr [edi], 0

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
IntToString ENDP

ReadLine PROC
    push ebx
    push ecx
    push edx
    push esi
    push edi

    mov esi, edx
    push STD_INPUT_HANDLE
    call GetStdHandle
    mov edi, eax

    push 0
    push OFFSET charsRead
    push MAX_LEN
    push esi
    push edi
    call ReadConsoleA

    mov ecx, charsRead
    sub ecx, 2

    cmp ecx, 0
    jl RL_Empty

    mov byte ptr [esi + ecx], 0
    jmp RL_Exit

RL_Empty:
    mov byte ptr [esi], 0

RL_Exit:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
ReadLine ENDP

Branch1 PROC
    push eax
    push edx

    fild dword ptr [esp + 4]
    fild dword ptr [esp]
    fmulp
    fimul dword ptr [valFour]
    fiadd dword ptr [valFive]
    fistp dword ptr [valRes]

    add esp, 8
    ret
Branch1 ENDP

Branch2 PROC
    push eax
    push edx

    fild dword ptr [esp + 4]
    fild dword ptr [esp]
    fmulp
    fimul dword ptr [valThree]

    fild dword ptr [esp]
    fimul dword ptr [valTwo]
    faddp

    fild dword ptr [esp + 4]
    fild dword ptr [esp + 4]
    fmulp

    fild dword ptr [esp]
    fild dword ptr [esp]
    fmulp

    faddp
    fiadd dword ptr [valOne]

    fdivp
    fistp dword ptr [valRes]

    add esp, 8
    ret
Branch2 ENDP

Branch3 PROC
    push eax
    push edx

    fild dword ptr [esp + 4]
    fimul dword ptr [valSix]

    fild dword ptr [esp]
    fild dword ptr [esp]
    fmulp
    fimul dword ptr [valTwo]

    fsubp
    fiadd dword ptr [valOne]
    fistp dword ptr [valRes]

    add esp, 8
    ret
Branch3 ENDP

start PROC
    push 1251
    call SetConsoleCP
    push 1251
    call SetConsoleOutputCP

    mov edx, OFFSET promptX
    call PrintString
    mov edx, OFFSET bufX
    call ReadLine
    mov edx, OFFSET bufX
    call ParseInt
    mov valX, eax

    mov edx, OFFSET promptY
    call PrintString
    mov edx, OFFSET bufY
    call ReadLine
    mov edx, OFFSET bufY
    call ParseInt
    mov edx, eax

    mov eax, valX

    push eax
    push edx
    add eax, edx

    cmp eax, 10
    jg DoBranch1

    cmp eax, -2
    jl DoBranch2

    mov edx, OFFSET branchMsg
    call PrintString
    mov edx, OFFSET b3Text
    call PrintString

    pop edx
    pop eax
    call Branch3
    jmp ShowResult

DoBranch1:
    mov edx, OFFSET branchMsg
    call PrintString
    mov edx, OFFSET b1Text
    call PrintString

    pop edx
    pop eax
    call Branch1
    jmp ShowResult

DoBranch2:
    mov edx, OFFSET branchMsg
    call PrintString
    mov edx, OFFSET b2Text
    call PrintString

    pop edx
    pop eax
    call Branch2

ShowResult:
    mov edx, OFFSET resMsg
    call PrintString

    mov eax, valRes
    mov edx, OFFSET outBuf
    call IntToString

    mov edx, OFFSET outBuf
    call PrintString

    mov edx, OFFSET newline
    call PrintString

    push 0
    call ExitProcess
start ENDP

END start