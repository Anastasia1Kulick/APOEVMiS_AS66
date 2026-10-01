.386
.model flat, stdcall
option casemap:none

includelib kernel32.lib

GetStdHandle PROTO :DWORD
ReadConsoleW PROTO :DWORD, :PTR WORD, :DWORD, :PTR DWORD, :DWORD
WriteConsoleW PROTO :DWORD, :PTR WORD, :DWORD, :PTR DWORD, :DWORD
ExitProcess PROTO :DWORD

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11

.data

msgInput  WORD 'V','v','e','d','i','t','e',' ','s','t','r','o','k','u',':',' ',0
msgOutput WORD 13,10,'R','e','z','u','l','t','a','t',':',' ',0

buffer WORD 1024 DUP(0)

input_length  DWORD 0
output_length DWORD 0
written       DWORD 0

hInput  DWORD 0
hOutput DWORD 0

.code

DELETE_SPACES MACRO STRING, LENGTH, NEW_LENGTH
    LOCAL DS_LOOP, DS_END, DS_SKIP

    push eax
    push ecx
    push edx
    push esi
    push edi

    lea esi, STRING
    lea edi, STRING
    mov ecx, LENGTH
    xor edx, edx

DS_LOOP:
    cmp ecx, 0
    je DS_END

    mov ax, [esi]
    add esi, 2
    dec ecx

    cmp ax, ' '
    je DS_SKIP

    mov [edi], ax
    add edi, 2
    inc edx

DS_SKIP:
    jmp DS_LOOP

DS_END:
    mov NEW_LENGTH, edx

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
ENDM

main PROC

    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hInput, eax

    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hOutput, eax

    invoke WriteConsoleW, hOutput, ADDR msgInput, 16, ADDR written, 0

    invoke ReadConsoleW, hInput, ADDR buffer, 1023, ADDR input_length, 0

    mov eax, input_length

    cmp eax, 2
    jb NO_CRLF

    sub eax, 2

NO_CRLF:
    mov input_length, eax

    DELETE_SPACES buffer, input_length, output_length

    invoke WriteConsoleW, hOutput, ADDR msgOutput, 12, ADDR written, 0

    invoke WriteConsoleW, hOutput, ADDR buffer, output_length, ADDR written, 0

    invoke ExitProcess, 0

main ENDP

END main