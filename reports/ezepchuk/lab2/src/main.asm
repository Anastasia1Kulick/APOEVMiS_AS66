.386
.model flat,stdcall
option casemap:none

includelib kernel32.lib

ExitProcess PROTO :DWORD
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
SetConsoleCP PROTO :DWORD
SetConsoleOutputCP PROTO :DWORD

STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11
MAX_LEN EQU 100

.const

prompt db "Vvedite tekst (do 100 simvolov, konec - '.'): ",0
nottext db 13,10,"Vvedennaya posledovatelnost ne yavlyaetsya tekstom.",13,10,0
condition db 13,10,"Proveryaem uslovie: chislo propisnyh latinskih bukv ravno chislu propisnyh russkih bukv.",13,10,0
true_msg db "Uslovie vypolneno.",13,10,0
false_msg db "Uslovie ne vypolneno.",13,10,0
original db "Ishodny tekst: ",0
result db 13,10,"Preobrazovannyi tekst: ",0
newline db 13,10,0

.code

PrintString PROC
    push eax
    push ecx
    push edx
    push esi
    push edi

    mov esi,edx
    xor ecx,ecx

PRINT_LOOP:
    cmp byte ptr [esi],0
    je PRINT_DONE
    inc esi
    inc ecx
    jmp PRINT_LOOP

PRINT_DONE:
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov edi,eax

    sub esp,4
    mov eax,esp

    push 0
    push eax
    push ecx
    push edx
    push edi
    call WriteConsoleA

    add esp,4

    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
PrintString ENDP

ReadText PROC
    push ebp
    mov ebp,esp
    sub esp,16

    push ebx
    push esi
    push edi

    mov esi,edx
    xor ebx,ebx
    mov dword ptr [ebp-16],0

    push STD_INPUT_HANDLE
    call GetStdHandle
    mov edi,eax

READ_LOOP:
    lea edx,[ebp-4]

    push 0
    lea eax,[ebp-8]
    push eax
    push 1
    push edx
    push edi
    call ReadConsoleA

    test eax,eax
    jz READ_ERROR

    movzx eax,byte ptr [ebp-4]

    cmp eax,'.'
    je READ_END

    cmp eax,13
    je READ_ERROR

    cmp eax,10
    je READ_ERROR

    cmp ebx,MAX_LEN
    jae READ_OVERFLOW

    mov byte ptr [esi],al
    inc esi
    inc ebx

    jmp READ_LOOP

READ_OVERFLOW:
    mov dword ptr [ebp-16],1
    jmp READ_LOOP

READ_END:
    cmp dword ptr [ebp-16],1
    je READ_ERROR

    mov byte ptr [esi],0
    mov eax,ebx
    jmp READ_EXIT

READ_ERROR:
    mov eax,-1

READ_EXIT:
    pop edi
    pop esi
    pop ebx

    mov esp,ebp
    pop ebp
    ret
ReadText ENDP

IsText PROC
    push ecx
    push edx
    push esi

    cmp eax,0
    je TEXT_ERROR

    mov ecx,eax
    mov esi,edx

TEXT_LOOP:
    movzx edx,byte ptr [esi]

    cmp edx,20h
    jb TEXT_ERROR

    cmp edx,7Fh
    je TEXT_ERROR

    inc esi
    dec ecx
    jnz TEXT_LOOP

    mov eax,1
    jmp TEXT_EXIT

TEXT_ERROR:
    xor eax,eax

TEXT_EXIT:
    pop esi
    pop edx
    pop ecx
    ret
IsText ENDP

CheckCondition PROC
    push ebx
    push ecx
    push esi
    push edi

    xor ebx,ebx
    xor edi,edi

    mov ecx,eax
    mov esi,edx

CONDITION_LOOP:
    movzx eax,byte ptr [esi]

    cmp eax,'A'
    jb CHECK_RUSSIAN
    cmp eax,'Z'
    ja CHECK_RUSSIAN

    inc ebx
    jmp CONDITION_NEXT

CHECK_RUSSIAN:
    cmp eax,0A8h
    je RUSSIAN_FOUND

    cmp eax,0C0h
    jb CONDITION_NEXT

    cmp eax,0DFh
    ja CONDITION_NEXT

RUSSIAN_FOUND:
    inc edi

CONDITION_NEXT:
    inc esi
    dec ecx
    jnz CONDITION_LOOP

    mov eax,ebx
    mov edx,edi

    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
CheckCondition ENDP

TransformText PROC
    push ecx
    push esi

    mov ecx,eax
    mov esi,edx

TRANSFORM_LOOP:
    mov al,[esi]

    cmp al,'a'
    jb CHECK_UPPER
    cmp al,'z'
    ja CHECK_UPPER

    sub al,20h
    mov [esi],al
    jmp TRANSFORM_NEXT

CHECK_UPPER:
    cmp al,'A'
    jb TRANSFORM_NEXT
    cmp al,'Z'
    ja TRANSFORM_NEXT

    add al,20h
    mov [esi],al

TRANSFORM_NEXT:
    inc esi
    dec ecx
    jnz TRANSFORM_LOOP

    pop esi
    pop ecx
    ret
TransformText ENDP

start PROC
    push ebp
    mov ebp,esp
    sub esp,116

    push 1251
    call SetConsoleCP

    push 1251
    call SetConsoleOutputCP

    mov edx,OFFSET prompt
    call PrintString

    lea edx,[ebp-104]
    call ReadText

    cmp eax,-1
    je ERROR_TEXT

    mov [ebp-108],eax

    lea edx,[ebp-104]
    mov eax,[ebp-108]
    call IsText

    cmp eax,1
    jne ERROR_TEXT

    mov edx,OFFSET condition
    call PrintString

    lea edx,[ebp-104]
    mov eax,[ebp-108]
    call CheckCondition

    mov [ebp-112],eax
    mov [ebp-116],edx

    cmp eax,edx
    jne CONDITION_FALSE

    mov edx,OFFSET true_msg
    call PrintString

    mov edx,OFFSET original
    call PrintString

    lea edx,[ebp-104]
    call PrintString

    lea edx,[ebp-104]
    mov eax,[ebp-108]
    call TransformText

    mov edx,OFFSET result
    call PrintString

    lea edx,[ebp-104]
    call PrintString

    mov edx,OFFSET newline
    call PrintString

    push 0
    call ExitProcess

CONDITION_FALSE:
    mov edx,OFFSET false_msg
    call PrintString

    push 0
    call ExitProcess

ERROR_TEXT:
    mov edx,OFFSET nottext
    call PrintString

    push 0
    call ExitProcess

start ENDP

END start