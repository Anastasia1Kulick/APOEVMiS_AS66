; Laboratory work No. 3. Variant 14
; Task: delete from a string all words that contain at least one Latin letter.
;       A word is a sequence of characters between spaces.
; The processing is written as the macro DEL_LATIN_WORDS.
;
; MASM, x64, Windows console (Visual Studio, ml64).

OPTION CASEMAP:NONE

includelib kernel32.lib

GetStdHandle PROTO
ReadFile     PROTO
WriteFile    PROTO
ExitProcess  PROTO

STD_INPUT_HANDLE  EQU -10
STD_OUTPUT_HANDLE EQU -11

INPUT_BUF_SIZE    EQU 256       ; size of the input buffer

; ---------------------------------------------------------------------------
; DEL_LATIN_WORDS - deletes from a zero-terminated string all words that
; contain at least one Latin letter. A deleted word is removed together with
; the spaces after it; if the last word is deleted, the spaces at the end of
; the result are removed too. The string is processed in place.
; Parameter: buf - memory operand with the address of the string, e.g. [rcx]
; Changes:   rax, rcx, rdx, r8 - r11 (volatile registers only)
; ---------------------------------------------------------------------------
DEL_LATIN_WORDS MACRO buf
    LOCAL dl_lead, dl_loop, dl_scan, dl_not_latin, dl_scan_end
    LOCAL dl_copy_word, dl_copy_sp, dl_kept, dl_skip_sp, dl_deleted
    LOCAL dl_trim, dl_trim_loop, dl_finish

    lea  r8, buf                ; r8 = read pointer
    mov  r9, r8                 ; r9 = write pointer
    mov  rdx, r8                ; rdx = start of the string
    xor  ecx, ecx               ; ecx = 1 if the last word was deleted
dl_lead:                        ; leading spaces are copied as they are
    cmp  byte ptr [r8], ' '
    jne  dl_loop
    mov  byte ptr [r9], ' '
    inc  r8
    inc  r9
    jmp  dl_lead
dl_loop:                        ; next word
    cmp  byte ptr [r8], 0
    je   dl_trim
    mov  r10, r8                ; r10 = start of the word
    xor  r11d, r11d             ; r11d = 1 if the word has a Latin letter
dl_scan:
    mov  al, byte ptr [r8]
    test al, al
    jz   dl_scan_end
    cmp  al, ' '
    je   dl_scan_end
    or   al, 20h                ; to lower case
    sub  al, 'a'
    cmp  al, 25                 ; 'a' .. 'z'
    ja   dl_not_latin
    mov  r11d, 1
dl_not_latin:
    inc  r8
    jmp  dl_scan
dl_scan_end:                    ; the word is [r10, r8)
    test r11d, r11d
    jnz  dl_skip_sp
dl_copy_word:                   ; no Latin letters: copy the word
    cmp  r10, r8
    jae  dl_copy_sp
    mov  al, byte ptr [r10]
    mov  byte ptr [r9], al
    inc  r10
    inc  r9
    jmp  dl_copy_word
dl_copy_sp:                     ; and the spaces after it
    cmp  byte ptr [r8], ' '
    jne  dl_kept
    mov  byte ptr [r9], ' '
    inc  r8
    inc  r9
    jmp  dl_copy_sp
dl_kept:
    xor  ecx, ecx
    jmp  dl_loop
dl_skip_sp:                     ; Latin letter found: skip the word and the spaces
    cmp  byte ptr [r8], ' '
    jne  dl_deleted
    inc  r8
    jmp  dl_skip_sp
dl_deleted:
    mov  ecx, 1
    jmp  dl_loop
dl_trim:                        ; the last word was deleted: cut the trailing spaces
    test ecx, ecx
    jz   dl_finish
dl_trim_loop:
    cmp  r9, rdx
    je   dl_finish
    cmp  byte ptr [r9 - 1], ' '
    jne  dl_finish
    dec  r9
    jmp  dl_trim_loop
dl_finish:
    mov  byte ptr [r9], 0
ENDM

.const

msgTitle    db "Laboratory work No. 3. Variant 14", 13, 10, 13, 10, 0
msgTask     db "Task: delete from the string all words that contain at least one Latin", 13, 10
            db "letter. A word is a sequence of characters between spaces; a deleted", 13, 10
            db "word is removed together with the spaces after it.", 13, 10
            db "Processing is done by the macro DEL_LATIN_WORDS.", 13, 10, 0
msgPrompt   db 13, 10, "Enter a string of words (an empty line - exit):", 13, 10, 0
msgOriginal db "Original string: [", 0
msgResult   db "Result string:   [", 0
msgClose    db "]", 13, 10, 0
msgBye      db 13, 10, "The program is finished.", 13, 10, 0

.code

; ---------------------------------------------------------------------------
; PrintStr - prints a zero-terminated string to the console.
; In:  rcx = address of the string
; ---------------------------------------------------------------------------
PrintStr PROC
    push rbx
    push rsi
    sub  rsp, 38h               ; 20h shadow space + 5th argument + local

    mov  rsi, rcx
    xor  ebx, ebx               ; ebx = string length
ps_len:
    cmp  byte ptr [rsi + rbx], 0
    je   ps_write
    inc  ebx
    jmp  ps_len

ps_write:
    mov  ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov  rcx, rax               ; hFile
    mov  rdx, rsi               ; lpBuffer
    mov  r8d, ebx               ; nNumberOfBytesToWrite
    lea  r9, [rsp + 28h]        ; lpNumberOfBytesWritten
    mov  qword ptr [rsp + 20h], 0   ; lpOverlapped
    call WriteFile

    add  rsp, 38h
    pop  rsi
    pop  rbx
    ret
PrintStr ENDP

; ---------------------------------------------------------------------------
; InputLine - reads a line from the console and removes the end of line.
; In:  rcx = address of the buffer, edx = size of the buffer
; Out: eax = length of the string, or -1 if nothing was read
; ---------------------------------------------------------------------------
InputLine PROC
    push rbx
    push rsi
    sub  rsp, 38h

    mov  rsi, rcx               ; rsi = buffer
    mov  ebx, edx
    dec  ebx                    ; ebx = number of bytes to read

    mov  ecx, STD_INPUT_HANDLE
    call GetStdHandle
    mov  rcx, rax               ; hFile
    mov  rdx, rsi               ; lpBuffer
    mov  r8d, ebx               ; nNumberOfBytesToRead
    lea  r9, [rsp + 28h]        ; lpNumberOfBytesRead
    mov  qword ptr [rsp + 20h], 0   ; lpOverlapped
    call ReadFile
    test eax, eax
    jz   il_fail

    mov  ecx, dword ptr [rsp + 28h] ; ecx = number of bytes read
    test ecx, ecx
    jz   il_fail
    xor  eax, eax               ; eax = index in the buffer
il_scan:
    cmp  eax, ecx
    jae  il_end
    mov  dl, byte ptr [rsi + rax]
    cmp  dl, 13                 ; CR
    je   il_end
    cmp  dl, 10                 ; LF
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

; ---------------------------------------------------------------------------
; ProcessText - deletes the words with Latin letters (macro call).
; In:  rcx = address of the zero-terminated string
; ---------------------------------------------------------------------------
ProcessText PROC
    DEL_LATIN_WORDS [rcx]
    ret
ProcessText ENDP

; ---------------------------------------------------------------------------
; main - the program entry point.
; The string buffer is a local array on the stack (no global variables).
; ---------------------------------------------------------------------------
main PROC
    sub  rsp, 128h              ; 20h shadow space + 100h buffer + 8 alignment

    lea  rcx, msgTitle
    call PrintStr
    lea  rcx, msgTask
    call PrintStr

m_next:
    lea  rcx, msgPrompt
    call PrintStr

    ; input
    lea  rcx, [rsp + 20h]
    mov  edx, INPUT_BUF_SIZE
    call InputLine
    test eax, eax
    jle  m_exit                 ; empty line or end of input

    lea  rcx, msgOriginal
    call PrintStr
    lea  rcx, [rsp + 20h]
    call PrintStr
    lea  rcx, msgClose
    call PrintStr

    ; processing
    lea  rcx, [rsp + 20h]
    call ProcessText

    ; output of the result
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