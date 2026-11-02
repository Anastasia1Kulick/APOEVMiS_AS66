.model small
.386
.stack 100h
.387

.data
    msgX    db 'Enter x (integer, |x|<=10000): $'
    msgY    db 'Enter y (integer, |y|<=10000): $'
    msgB1   db 'Branch 1: x + y > 2', 13, 10, '$'
    msgB2   db 'Branch 2: x + y < -10', 13, 10, '$'
    msgB3   db 'Branch 3: -10 <= x + y <= 2', 13, 10, '$'
    msgRes  db 'Result y = $'
    msgEnd  db 13, 10, ' '
    crlf    db 13, 10, '$'

    buf     db 8, 0, 8 dup(0)      

    x       dw ?
    y       dw ?
    int_part dd ?                  
    frac    dd ?                   
    million dd 1000000

    
    c1      dw 1
    c2      dw 2
    c3      dw 3
    c4      dw 4
    c5      dw 5
    c7      dw 7

    cw_old  dw ?
    cw_new  dw ?

.code


PrintStr proc
    mov ah, 9
    int 21h
    ret
PrintStr endp


ReadInt proc
    push bx
    push cx
    push dx
    push si
    push di

    mov ah, 0Ah
    mov dx, offset buf
    int 21h

    mov dx, offset crlf
    call PrintStr

    mov si, offset buf + 2
    xor bx, bx                 
    xor di, di                 
    cmp byte ptr [si], '-'
    jne rd_loop
    inc di
    inc si
rd_loop:
    mov al, [si]
    cmp al, 13
    je  rd_done
    sub al, '0'
    xor ah, ah
    push ax
    mov ax, bx
    mov cx, 10
    mul cx                     
    mov bx, ax
    pop ax
    add bx, ax
    inc si
    jmp rd_loop
rd_done:
    mov ax, bx
    test di, di
    jz  rd_exit
    neg ax
rd_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
ReadInt endp

PrintU32 proc
    push ebx
    push ecx
    push edx
    mov ebx, 10
    xor cx, cx
pu_div:
    xor edx, edx
    div ebx
    push dx
    inc cx
    test eax, eax
    jnz pu_div
pu_out:
    pop dx
    add dl, '0'
    mov ah, 2
    int 21h
    loop pu_out
    pop edx
    pop ecx
    pop ebx
    ret
PrintU32 endp


PrintFrac proc
    push eax
    push ebx
    push ecx
    push edx
    mov eax, frac
    mov ebx, 100000
    mov cx, 6
pf_loop:
    xor edx, edx
    div ebx                    
    push edx
    mov dl, al
    add dl, '0'
    mov ah, 2
    int 21h
    pop edx
    mov eax, edx               
    push eax
    mov eax, ebx
    xor edx, edx
    mov ebx, 10
    div ebx                    
    mov ebx, eax
    pop eax
    dec cx
    jnz pf_loop
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
PrintFrac endp


PrintReal proc
    fstcw cw_old
    mov ax, cw_old
    or  ax, 0C00h              
    mov cw_new, ax
    fldcw cw_new

    ftst                       
    fstsw ax
    sahf
    jae pr_pos                 
    fabs
    mov dl, '-'
    mov ah, 2
    int 21h
pr_pos:
    fld   st(0)
    fistp int_part             
    fisub int_part             
    fimul million              
    fistp frac

    mov eax, int_part
    call PrintU32
    mov dl, '.'
    mov ah, 2
    int 21h
    call PrintFrac

    fldcw cw_old
    ret
PrintReal endp


Branch1 proc
    fild  x                    
    fimul c4                   
    fiadd y                    
    fisub c3                   
    ret
Branch1 endp


Branch2 proc
    fild  x
    fimul y                    
    fimul c3                   
    fild  y
    fimul c2                   
    faddp st(1), st            

    fild  x
    fimul x                    
    fild  y
    fimul y
    fimul c2                   
    faddp st(1), st            
    fiadd c1                   

    fdivp st(1), st            
    ret
Branch2 endp


Branch3 proc
    fild  x
    fimul c5                   
    fild  y
    fimul y
    fimul c3                   
    fsubp st(1), st            
    fiadd c7                   
    ret
Branch3 endp


CalcFunc proc
    mov ax, x
    add ax, y                  

    cmp ax, 2
    jg  cf_b1
    cmp ax, -10
    jl  cf_b2
    jmp cf_b3

cf_b1:
    mov dx, offset msgB1
    call PrintStr
    call Branch1
    ret
cf_b2:
    mov dx, offset msgB2
    call PrintStr
    call Branch2
    ret
cf_b3:
    mov dx, offset msgB3
    call PrintStr
    call Branch3
    ret
CalcFunc endp


start:
    mov ax, @data
    mov ds, ax

    mov dx, offset msgX
    call PrintStr
    call ReadInt
    mov x, ax

    mov dx, offset msgY
    call PrintStr
    call ReadInt
    mov y, ax

    finit
    call CalcFunc              

    mov dx, offset msgRes
    call PrintStr
    call PrintReal

    mov dx, offset msgEnd
    call PrintStr
    mov ah, 1
    int 21h

    mov ax, 4C00h
    int 21h
end start