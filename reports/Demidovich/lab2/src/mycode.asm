.MODEL small
.STACK 100h

.DATA
    MAX_LEN EQU 100
    
    msg_prompt  DB 'Enter text (end with "."): $'
    msg_empty   DB 13, 10, 'Error: The input is empty or not a text.$'
    msg_fail    DB 13, 10, 'Condition not met: less than 3 Latin letters.$'
    msg_pass    DB 13, 10, 'Condition met! Transforming...$'
    msg_result  DB 13, 10, 'Result text: $'
    
    text_buffer DB MAX_LEN DUP(?)
    text_len    DW 0

.CODE
START:
    mov ax, @data
    mov ds, ax
    mov es, ax

    mov ah, 09h
    lea dx, msg_prompt
    int 21h

    lea di, text_buffer
    mov cx, 0

input_loop:
    mov ah, 01h
    int 21h
    cmp al, '.'
    je end_input
    
    mov [di], al
    inc di
    inc cx
    
    cmp cx, MAX_LEN
    je end_input
    jmp input_loop

end_input:
    mov text_len, cx

    cmp cx, 0
    je is_empty

    lea si, text_buffer
    mov cx, text_len
    call CheckCondition
    
    cmp al, 1
    jne cond_failed

    mov ah, 09h
    lea dx, msg_pass
    int 21h

    lea si, text_buffer
    mov cx, text_len
    call TransformText

    mov ah, 09h
    lea dx, msg_result
    int 21h

    lea si, text_buffer
    mov cx, text_len
print_loop:
    mov ah, 02h
    mov dl, [si]
    int 21h
    inc si
    loop print_loop
    jmp exit_prog

is_empty:
    mov ah, 09h
    lea dx, msg_empty
    int 21h
    jmp exit_prog

cond_failed:
    mov ah, 09h
    lea dx, msg_fail
    int 21h

exit_prog:
    mov ax, 4C00h
    int 21h

CheckCondition PROC
    push bx
    push cx
    push si

    mov bx, 0

check_loop:
    mov al, [si]
    
    call IsLatinLetter
    cmp ah, 1
    jne not_letter
    inc bx

not_letter:
    inc si
    loop check_loop

    cmp bx, 3
    jae cond_true
    mov al, 0
    jmp end_check

cond_true:
    mov al, 1

end_check:
    pop si
    pop cx
    pop bx
    ret
CheckCondition ENDP

TransformText PROC
    push cx
    push si

trans_loop:
    mov al, [si]
    
    cmp al, 'A'
    jb skip_trans
    cmp al, 'Z'
    ja skip_trans
    
    cmp al, 'Z'
    je is_Z
    
    inc al
    mov [si], al
    jmp skip_trans

is_Z:
    mov byte ptr [si], 'A'

skip_trans:
    inc si
    loop trans_loop

    pop si
    pop cx
    ret
TransformText ENDP

IsLatinLetter PROC
    mov ah, 0
    
    cmp al, 'A'
    jb check_lower
    cmp al, 'Z'
    ja check_lower
    mov ah, 1
    ret

check_lower:
    cmp al, 'a'
    jb end_is_letter
    cmp al, 'z'
    ja end_is_letter
    mov ah, 1

end_is_letter:
    ret
IsLatinLetter ENDP

END START