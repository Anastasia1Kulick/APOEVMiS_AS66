.386
.model flat, c
option casemap:none

MAX_LENGTH equ 100

printf PROTO C :PTR BYTE, :VARARG
getchar PROTO C
fflush PROTO C :DWORD
SetConsoleCP PROTO STDCALL :DWORD
SetConsoleOutputCP PROTO STDCALL :DWORD

.const
title_text db "Lab 2. Variant 12.", 10, 0
condition_text db "Condition: lowercase Russian letters = digits.", 10, 0
rule_text db "Transformation: cyclic shift by 3 positions to the left.", 10, 0
prompt_text db "Enter 1-100 characters, finish with a dot: ", 0
new_line db 10, 0
original_text db "Original: [%s]", 10, 0
result_text db "Result:   [%s]", 10, 0
true_text db "Condition is true.", 10, 0
false_text db "Condition is false. The text is not transformed.", 10, 0
invalid_text db "Invalid input: enter 1-100 characters and a final dot.", 10, 0

.code
check_condition PROC uses esi ebx, text:PTR BYTE, text_size:DWORD
    mov esi, text
    mov ecx, text_size
    xor ebx, ebx
    xor edx, edx
check_next:
    mov al, [esi]
    cmp al, '0'
    jb check_letter
    cmp al, '9'
    ja check_letter
    inc edx
    jmp check_continue
check_letter:
    cmp al, 0B8h
    je found_letter
    cmp al, 0E0h
    jb check_continue
found_letter:
    inc ebx
check_continue:
    inc esi
    loop check_next
    xor eax, eax
    cmp ebx, edx
    sete al
    ret
check_condition ENDP

shift_text PROC uses esi edi ebx, text:PTR BYTE, text_size:DWORD
    cld
    mov ebx, 3
shift_again:
    mov edi, text
    mov dl, [edi]
    lea esi, [edi + 1]
    mov ecx, text_size
    dec ecx
    rep movsb
    mov [edi], dl
    dec ebx
    jnz shift_again
    ret
shift_text ENDP

main PROC uses esi ebx
    LOCAL buffer[MAX_LENGTH + 1]:BYTE
    LOCAL text_size:DWORD
    LOCAL invalid:DWORD

    invoke SetConsoleCP, 1251
    invoke SetConsoleOutputCP, 1251
    invoke printf, ADDR title_text
    invoke printf, ADDR condition_text
    invoke printf, ADDR rule_text
    invoke printf, ADDR prompt_text
    invoke fflush, 0

    mov text_size, 0
    mov invalid, 0
read_next:
    invoke getchar
    cmp eax, -1
    je invalid_input
    cmp al, '.'
    je end_input
    cmp al, 13
    je read_next
    cmp al, 10
    je read_next
    cmp al, 0
    je bad_character
    cmp text_size, MAX_LENGTH
    jae bad_character
    lea esi, buffer
    add esi, text_size
    mov [esi], al
    inc text_size
    jmp read_next
bad_character:
    mov invalid, 1
    jmp read_next
end_input:
    invoke printf, ADDR new_line
    cmp text_size, 0
    je invalid_input
    cmp invalid, 0
    jne invalid_input
    lea esi, buffer
    add esi, text_size
    mov byte ptr [esi], 0
    invoke printf, ADDR original_text, ADDR buffer
    invoke check_condition, ADDR buffer, text_size
    test eax, eax
    jz condition_false
    invoke printf, ADDR true_text
    invoke shift_text, ADDR buffer, text_size
    invoke printf, ADDR result_text, ADDR buffer
    jmp finish
condition_false:
    invoke printf, ADDR false_text
    jmp finish
invalid_input:
    invoke printf, ADDR invalid_text
finish:
    xor eax, eax
    ret
main ENDP
END
