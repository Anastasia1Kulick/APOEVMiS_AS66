.model small
.stack 100h

.data
    MAX_LEN       equ 100

    sBanner       db "========================================================", 00Dh, 00Ah
                  db " Lab 2. Character Data Processing (TASM / DOSBox)", 00Dh, 00Ah
                  db " Condition: Ends with uppercase 'A'..'Z' not repeating.", 00Dh, 00Ah
                  db " Rule: Transform '1'..'9' -> 'a'..'i'.", 00Dh, 00Ah
                  db "========================================================", 00Dh, 00Ah, 00Dh, 00Ah, "$"

    sPrompt       db "Enter text:", 00Dh, 00Ah, "> $"
    sOrig         db 00Dh, 00Ah, "Original text: $"
    sCondTrue     db 00Dh, 00Ah, "Condition check: TRUE.", 00Dh, 00Ah, "Applying transformation...", 00Dh, 00Ah, "$"
    sCondFalse    db 00Dh, 00Ah, "Condition check: FALSE.", 00Dh, 00Ah, "Transformation skipped.", 00Dh, 00Ah, "$"
    sResult       db "Transformed text: $"
    sNoDot        db 00Dh, 00Ah, "Error: Dot '.' not found or empty input!", 00Dh, 00Ah, "$"

    textBuffer    db MAX_LEN dup(0)
    textLen       dw 0

.code


CheckCondition proc
    push bx
    push cx
    push si
    push di

    cmp cx, 0
    jbe cond_false

    mov si, bx
    add si, cx
    dec si                  
    mov al, [si]            

    cmp al, 'A'
    jb cond_false
    cmp al, 'Z'
    ja cond_false

    dec cx
    cmp cx, 0
    je cond_true

    mov di, bx
    cld                     

    repne scasb
    je cond_false

cond_true:
    mov ax, 1
    jmp finish_check

cond_false:
    xor ax, ax

finish_check:
    pop di
    pop si
    pop cx
    pop bx
    ret
CheckCondition endp


TransformText proc
    push bx
    push cx
    push si
    push ax

    mov si, bx

ttLoop:
    cmp cx, 0
    je ttDone

    mov al, [si]

    cmp al, '1'
    jb ttNext
    cmp al, '9'
    ja ttNext

    add al, 30h             
    mov [si], al

ttNext:
    inc si
    loop ttLoop

ttDone:
    pop ax
    pop si
    pop cx
    pop bx
    ret
TransformText endp


main:
    mov ax, @data
    mov ds, ax
    mov es, ax              

    ; Печать баннера
    mov ah, 09h
    mov dx, offset sBanner
    int 21h

    ; Печать приглашения
    mov ah, 09h
    mov dx, offset sPrompt
    int 21h

    
    mov bx, offset textBuffer
    xor cx, cx              

readLoop:
    cmp cx, MAX_LEN
    jge readDone

    mov ah, 01h             
    int 21h

    
    cmp al, '.'             
    je readDone
    cmp al, ','            
    je readDone
    cmp al, 00Dh            
    je readDone

    
    mov [bx], al
    inc bx
    inc cx
    jmp readLoop

readDone:
    mov textLen, cx

    cmp textLen, 0
    je printNoDot

    
    mov ah, 09h
    mov dx, offset sOrig
    int 21h

    mov bx, offset textBuffer
    mov cx, textLen
printOrig:
    mov dl, [bx]
    mov ah, 02h
    int 21h
    inc bx
    loop printOrig

   
    mov bx, offset textBuffer
    mov cx, textLen
    call CheckCondition

    cmp ax, 1
    jne condFailed

    ; ИСТИНА:
    mov ah, 09h
    mov dx, offset sCondTrue
    int 21h

    
    mov bx, offset textBuffer
    mov cx, textLen
    call TransformText

    
    mov ah, 09h
    mov dx, offset sResult
    int 21h

    mov bx, offset textBuffer
    mov cx, textLen
printRes:
    mov dl, [bx]
    mov ah, 02h
    int 21h
    inc bx
    loop printRes

    jmp exitProg

condFailed:
    mov ah, 09h
    mov dx, offset sCondFalse
    int 21h
    jmp exitProg

printNoDot:
    mov ah, 09h
    mov dx, offset sNoDot
    int 21h

exitProg:
    mov ax, 4C00h
    int 21h

end main