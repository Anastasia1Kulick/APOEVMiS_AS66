.386
.model flat, c
option casemap:none

printf PROTO C :PTR BYTE, :VARARG
getchar PROTO C
fflush PROTO C :DWORD
SetConsoleCP PROTO STDCALL :DWORD
SetConsoleOutputCP PROTO STDCALL :DWORD

REMOVE_RUSSIAN_WORDS MACRO text
    LOCAL next_word, skip_space, scan_word, russian_letter
    LOCAL scan_next, scan_continue, word_end, copy_word, finish
    lea esi, text
    lea edi, text
next_word:
skip_space:
    cmp byte ptr [esi], ' '
    jne scan_word
    inc esi
    jmp skip_space
scan_word:
    cmp byte ptr [esi], 0
    je finish
    mov ebx, esi
    xor edx, edx
scan_next:
    mov al, [esi]
    cmp al, 0
    je word_end
    cmp al, ' '
    je word_end
    cmp al, 0C0h
    jae russian_letter
    cmp al, 0A8h
    je russian_letter
    cmp al, 0B8h
    jne scan_continue
russian_letter:
    mov edx, 1
scan_continue:
    inc esi
    jmp scan_next
word_end:
    test edx, edx
    jnz next_word
    lea eax, text
    cmp edi, eax
    je copy_word
    mov byte ptr [edi], ' '
    inc edi
copy_word:
    mov al, [ebx]
    mov [edi], al
    inc ebx
    inc edi
    cmp ebx, esi
    jb copy_word
    jmp next_word
finish:
    mov byte ptr [edi], 0
ENDM

.const
title_text db "Lab 3. Variant 12.", 10, 0
task_text db "Remove words containing Russian letters.", 10, 0
prompt_text db "Enter a line (up to 255 characters): ", 0
original_text db 10, "Original: [%s]", 10, 0
result_text db "Result:   [%s]", 10, 0
error_text db 10, "Input error: the line is too long or input ended.", 10, 0

.code
main PROC uses esi edi ebx
    LOCAL buffer[256]:BYTE
    LOCAL text_size:DWORD
    LOCAL invalid:DWORD

    invoke SetConsoleCP, 1251
    invoke SetConsoleOutputCP, 1251
    invoke printf, ADDR title_text
    invoke printf, ADDR task_text
    invoke printf, ADDR prompt_text
    invoke fflush, 0
    mov text_size, 0
    mov invalid, 0
read_next:
    invoke getchar
    cmp eax, -1
    je end_file
    cmp al, 10
    je end_input
    cmp al, 13
    je read_next
    cmp al, 0
    je bad_character
    cmp text_size, 255
    jae bad_character
    lea esi, buffer
    add esi, text_size
    mov [esi], al
    inc text_size
    jmp read_next
bad_character:
    mov invalid, 1
    jmp read_next
end_file:
    cmp text_size, 0
    je input_error
end_input:
    cmp invalid, 0
    jne input_error
    lea esi, buffer
    add esi, text_size
    mov byte ptr [esi], 0
    invoke printf, ADDR original_text, ADDR buffer
    REMOVE_RUSSIAN_WORDS buffer
    invoke printf, ADDR result_text, ADDR buffer
    xor eax, eax
    ret
input_error:
    invoke printf, ADDR error_text
    mov eax, 1
    ret
main ENDP
END
