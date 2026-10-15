; APO EVMiS, lab 2, variant 12. MASM, x86, cdecl.
; Each DWORD stores one Unicode character. No global variables.
.386
.model flat, C
.code

; int CheckConditionAsm(text, length, letters, digits)
; Counts Russian lowercase letters (including yo) and ASCII digits.
; EAX = 1 when the counts are equal, otherwise EAX = 0.
CheckConditionAsm PROC USES esi ebx,
    pText:PTR DWORD, charCount:DWORD, pLetters:PTR DWORD, pDigits:PTR DWORD
    mov esi, pText
    mov ecx, charCount
    xor ebx, ebx
    xor edx, edx
    cld
    test ecx, ecx
    jz counts_ready

check_character:
    lodsd
    cmp eax, 0430h             ; Russian lowercase a
    jb check_yo
    cmp eax, 044Fh             ; Russian lowercase ya
    jbe count_letter
check_yo:
    cmp eax, 0451h             ; Russian lowercase yo
    je count_letter
    cmp eax, '0'
    jb next_character
    cmp eax, '9'
    ja next_character
    inc edx
    jmp next_character
count_letter:
    inc ebx
next_character:
    dec ecx
    jnz check_character

counts_ready:
    mov eax, pLetters
    mov [eax], ebx
    mov eax, pDigits
    mov [eax], edx
    xor eax, eax
    cmp ebx, edx
    sete al
    ret
CheckConditionAsm ENDP

; void RotateLeftAsm(text, length)
; Three left rotations; effective count is 3 mod length.
; A character is kept in EAX, the remaining characters move with REP MOVSD.
; No second text buffer and no pushes inside the rotation loop.
RotateLeftAsm PROC USES esi edi ebx,
    pText:PTR DWORD, charCount:DWORD
    cld
    mov ebx, charCount
    cmp ebx, 1
    jbe rotation_done
    mov eax, 3
    xor edx, edx
    div ebx
    mov ebx, edx              ; number of single-position rotations
    test ebx, ebx
    jz rotation_done

rotate_once:
    mov edi, pText
    mov eax, [edi]            ; retain the first character
    lea esi, [edi + 4]
    mov ecx, charCount
    dec ecx
    rep movsd                ; move text[1..n-1] to text[0..n-2]
    mov [edi], eax            ; append the retained character
    dec ebx
    jnz rotate_once

rotation_done:
    ret
RotateLeftAsm ENDP
END
