.686
.model flat, c

REVERSE_WORDS_MACRO MACRO src, buffer

    LOCAL find_end, start_scan, scan_words, find_start, start_found
    LOCAL copy_loop, skip_space, done, empty_str, copy_back_loop

    mov esi, src
    mov edi, buffer

    mov eax, esi
find_end:
    cmp byte ptr [eax], 0
    je start_scan
    inc eax
    jmp find_end

start_scan:
    dec eax 

scan_words:
    cmp eax, src
    jl done                

    cmp byte ptr [eax], ' ' 
    je skip_space

    mov ebx, eax              
find_start:
    cmp eax, src
    je start_found            
    cmp byte ptr [eax-1], ' ' 
    je start_found
    dec eax
    jmp find_start

start_found:
    push esi
    mov esi, eax
    mov ecx, ebx
    sub ecx, eax
    inc ecx                   

copy_loop:
    mov dl, [esi]
    mov [edi], dl
    inc esi
    inc edi
    loop copy_loop            

    mov byte ptr [edi], ' '
    inc edi
    
    pop esi
    dec eax 
    jmp scan_words

skip_space:
    dec eax 
    jmp scan_words

done:

    cmp edi, buffer
    je empty_str
    dec edi
empty_str:
    mov byte ptr [edi], 0

    mov esi, buffer
    mov edi, src
copy_back_loop:
    mov dl, [esi]
    mov [edi], dl
    inc esi
    inc edi
    cmp dl, 0
    jne copy_back_loop

ENDM 

.code
reverseWordsWrapper PROC strPtr:DWORD, bufPtr:DWORD
    
    REVERSE_WORDS_MACRO strPtr, bufPtr
    
    ret
reverseWordsWrapper ENDP

END