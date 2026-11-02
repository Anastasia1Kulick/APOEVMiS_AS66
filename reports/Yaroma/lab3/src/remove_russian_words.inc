; Lab 3, variant 12. One character is one Unicode DWORD.
; A word is a maximal sequence of characters other than ASCII space (20h).
; Delete a whole word if it contains А-Я, а-я, Ё or ё. Preserve all spaces.
;
; pText: pointer value (register or DWORD memory); inLength: character count.
; outLength and removedWords: distinct named DWORD variables (static or
; EBP-relative locals), outside the text buffer. outLength may alias inLength.
; Operands must not be ESP-relative. All GPRs are preserved; arithmetic flags
; are unspecified. Buffer must have room for inLength + 1 DWORDs.
; Time O(n), additional workspace O(1). No procedure calls inside this macro.

REMOVE_RUSSIAN_WORDS MACRO pText:REQ, inLength:REQ, outLength:REQ, removedWords:REQ
    LOCAL next_item, copy_space, scan_word, check_yo, russian_found, scan_advance
    LOCAL word_end, remove_word, copy_word, finished

    pushad
    push inLength
    push pText
    pop esi
    pop ecx
    mov edi, esi
    lea edx, [esi + ecx * 4]
    sub esp, 8
    mov DWORD PTR [esp], 0       ; number of removed words
    mov [esp + 4], esi           ; original buffer address

next_item:
    cmp esi, edx
    jae finished
    mov eax, [esi]
    cmp eax, 20h
    je copy_space
    mov ebx, esi                 ; beginning of the word
    xor ecx, ecx                 ; Russian-letter flag
scan_word:
    cmp esi, edx
    jae word_end
    mov eax, [esi]
    cmp eax, 20h
    je word_end
    cmp eax, 0410h
    jb check_yo
    cmp eax, 044Fh
    jbe russian_found
check_yo:
    cmp eax, 0401h
    je russian_found
    cmp eax, 0451h
    je russian_found
    jmp scan_advance
russian_found:
    mov ecx, 1
scan_advance:
    add esi, 4
    jmp scan_word
word_end:
    test ecx, ecx
    jnz remove_word
copy_word:
    cmp ebx, esi
    jae next_item
    mov eax, [ebx]
    mov [edi], eax
    add ebx, 4
    add edi, 4
    jmp copy_word
remove_word:
    inc DWORD PTR [esp]
    jmp next_item
copy_space:
    mov [edi], eax
    add esi, 4
    add edi, 4
    jmp next_item
finished:
    mov DWORD PTR [edi], 0
    mov eax, edi
    sub eax, [esp + 4]
    shr eax, 2
    mov outLength, eax
    mov eax, [esp]
    mov removedWords, eax
    add esp, 8
    popad
ENDM
