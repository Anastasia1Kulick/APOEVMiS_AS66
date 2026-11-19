; Laboratory work No. 3. Variant 4
; Task: move a given character, if it is present in the string, to the front
;       of the string. All occurrences are moved, preserving their order.
; MASM, x64, Windows console (Visual Studio, ml64).

OPTION CASEMAP:NONE

includelib kernel32.lib

GetStdHandle PROTO
ReadFile     PROTO
WriteFile    PROTO
ExitProcess  PROTO

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11
INPUT_BUF_SIZE    EQU 256

; ---------------------------------------------------------------------------
; MOVE_CHAR_TO_FRONT - moves every occurrence of the character CH to the front
; of the string. Uses a temporary buffer to avoid overlapping pointers.
; Parameters: buf - address of the string
;             tmp - address of the temporary buffer (same size as buf)
;             ch  - character to move (8-bit register or immediate)
; Changes:   rax, rcx, rdx, r8 - r11
; ---------------------------------------------------------------------------
MOVE_CHAR_TO_FRONT MACRO buf, tmp, ch
    LOCAL mcf_read, mcf_write, mcf_copy, mcf_done, mcf_back_loop, mcf_back_done

    lea  r10, buf               ; r10 = source buffer address
    lea  r11, tmp               ; r11 = temp buffer address
    mov  r9b, ch                ; r9b = character to move

    mov  rcx, r10
    mov  rdx, r11

mcf_read:                       ; first pass: copy all CH to temp
    mov  al, byte ptr [rcx]
    test al, al
    jz   mcf_write
    cmp  al, r9b
    jne  mcf_next
    mov  byte ptr [rdx], al
    inc  rdx
mcf_next:
    inc  rcx
    jmp  mcf_read

mcf_write:                      ; second pass: append all other characters
    mov  rcx, r10
mcf_copy:
    mov  al, byte ptr [rcx]
    test al, al
    jz   mcf_done
    cmp  al, r9b
    je   mcf_skip
    mov  byte ptr [rdx], al
    inc  rdx
mcf_skip:
    inc  rcx
    jmp  mcf_copy

mcf_done:
    mov  byte ptr [rdx], 0      ; terminate temp

    ; copy temp back to source
    mov  rcx, r11
    mov  rdx, r10
mcf_back_loop:
    mov  al, byte ptr [rcx]
    mov  byte ptr [rdx], al
    test al, al
    jz   mcf_back_done
    inc  rcx
    inc  rdx
    jmp  mcf_back_loop
mcf_back_done:
ENDM

.const

msgTitle    db "Laboratory work No. 3. Variant 4", 13, 10, 13, 10, 0
msgTask     db "Task: move a given character, if it is present in the string,", 13, 10
            db "to the front of the string. All occurrences are moved, the order", 13, 10
            db "of the remaining characters is preserved.", 13, 10
            db "Processing is done by the macro MOVE_CHAR_TO_FRONT.", 13, 10, 0
msgPrompt   db 13, 10, "Enter a string of words (an empty line - exit):", 13, 10, 0
msgChar     db "Enter the character to move to the front: ", 0
msgOriginal db "Original string: [", 0
msgResult   db "Result string:   [", 0
msgClose    db "]", 13, 10, 0
msgBye      db 13, 10, "The program is finished.", 13, 10, 0

.code

; PrintStr - prints a zero-terminated string. In: rcx = address.
PrintStr PROC
    push rbx
    push rsi
    sub  rsp, 38h

    mov  rsi, rcx
    xor  ebx, ebx
ps_len:
    cmp  byte ptr [rsi + rbx], 0
    je   ps_write
    inc  ebx
    jmp  ps_len
ps_write:
    mov  ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov  rcx, rax
    mov  rdx, rsi
    mov  r8d, ebx
    lea  r9, [rsp + 28h]
    mov  qword ptr [rsp + 20h], 0
    call WriteFile

    add  rsp, 38h
    pop  rsi
    pop  rbx
    ret
PrintStr ENDP

; InputLine - reads a line, removes CR/LF. In: rcx = buffer, edx = size.
InputLine PROC
    push rbx
    push rsi
    sub  rsp, 38h

    mov  rsi, rcx
    mov  ebx, edx
    dec  ebx

    mov  ecx, STD_INPUT_HANDLE
    call GetStdHandle
    mov  rcx, rax
    mov  rdx, rsi
    mov  r8d, ebx
    lea  r9, [rsp + 28h]
    mov  qword ptr [rsp + 20h], 0
    call ReadFile
    test eax, eax
    jz   il_fail

    mov  ecx, dword ptr [rsp + 28h]
    test ecx, ecx
    jz   il_fail
    xor  eax, eax
il_scan:
    cmp  eax, ecx
    jae  il_end
    mov  dl, byte ptr [rsi + rax]
    cmp  dl, 13
    je   il_end
    cmp  dl, 10
    je   il_end
    inc  eax
    jmp  il_scan
il_end:
    mov  byte ptr [rsi + rax], 0
    jmp  il_exit
il_fail:
    mov  eax, -1
il_exit:
    add  rsp, 38h
    pop  rsi
    pop  rbx
    ret
InputLine ENDP

; ProcessText - macro call. In: rcx = string, rdx = temp buffer, r8b = char.
ProcessText PROC
    MOVE_CHAR_TO_FRONT [rcx], [rdx], r8b
    ret
ProcessText ENDP

; ---------------------------------------------------------------------------
; main - the program entry point.
; Stack layout: string buf [rsp+20h], temp buf [rsp+120h], char buf [rsp+220h].
; ---------------------------------------------------------------------------
main PROC
    sub  rsp, 248h

    lea  rcx, msgTitle
    call PrintStr
    lea  rcx, msgTask
    call PrintStr

m_next:
    lea  rcx, msgPrompt
    call PrintStr

    lea  rcx, [rsp + 20h]
    mov  edx, INPUT_BUF_SIZE
    call InputLine
    test eax, eax
    jle  m_exit

    lea  rcx, msgOriginal
    call PrintStr
    lea  rcx, [rsp + 20h]
    call PrintStr
    lea  rcx, msgClose
    call PrintStr

    lea  rcx, msgChar
    call PrintStr
    lea  rcx, [rsp + 220h]
    mov  edx, 4
    call InputLine
    movzx r8d, byte ptr [rsp + 220h]

    lea  rcx, [rsp + 20h]
    lea  rdx, [rsp + 120h]
    call ProcessText

    lea  rcx, msgResult
    call PrintStr
    lea  rcx, [rsp + 20h]
    call PrintStr
    lea  rcx, msgClose
    call PrintStr
    jmp  m_next

m_exit:
    lea  rcx, msgBye
    call PrintStr
    xor  ecx, ecx
    call ExitProcess
main ENDP

END