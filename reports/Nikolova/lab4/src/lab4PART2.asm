.model small
.386
.stack 100h
.387

.data
    msgX    db 'Enter x (real, e.g. -12.5): $'
    msgY    db 'Enter y (real, e.g. 3.25): $'
    msgB1   db 'Branch 1: x + y > 2', 13, 10, '$'
    msgB2   db 'Branch 2: x + y < -10', 13, 10, '$'
    msgB3   db 'Branch 3: -10 <= x + y <= 2', 13, 10, '$'
    msgRes  db 'Result y = $'
    msgEnd  db 13, 10, 'Press any key...$'
    crlf    db 13, 10, '$'

    buf     db 20, 0, 20 dup(0)    

    x       dq ?
    y       dq ?

    
    one     dq 1.0
    two     dq 2.0
    three   dq 3.0
    four    dq 4.0
    five    dq 5.0
    seven   dq 7.0
    ten     dq 10.0
    minus10 dq -10.0


    digit    dw ?
    int_part dd ?
    frac     dd ?
    million  dd 1000000
    cw_old   dw ?
    cw_new   dw ?

.code


PrintStr proc
    mov ah, 9
    int 21h
    ret
PrintStr endp


ReadReal proc
    push ax
    push dx
    push si
    push di

    mov ah, 0Ah
    mov dx, offset buf
    int 21h
    mov dx, offset crlf
    call PrintStr

    mov si, offset buf + 2
    xor di, di                 
    fldz                       
    cmp byte ptr [si], '-'
    jne rr_int
    inc di
    inc si

rr_int:                        
    mov al, [si]
    cmp al, '.'
    je  rr_dot
    cmp al, ','
    je  rr_dot
    cmp al, 13
    je  rr_done
    sub al, '0'
    xor ah, ah
    mov digit, ax
    fmul ten                   
    fiadd digit                
    inc si
    jmp rr_int

rr_dot:                        
    inc si
    fld1                       
rr_frac:
    mov al, [si]
    cmp al, 13
    je  rr_fdone
    sub al, '0'
    xor ah, ah
    mov digit, ax
    fdiv ten                   
    fild digit                 
    fmul st, st(1)             
    faddp st(2), st            
    inc si
    jmp rr_frac
rr_fdone:
    fstp st(0)                

rr_done:
    test di, di
    jz  rr_exit
    fchs                       
rr_exit:
    pop di
    pop si
    pop dx
    pop ax
    ret
ReadReal endp


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
    fld  x                    
    fmul four                  
    fadd y                    
    fsub three                 
    ret
Branch1 endp


Branch2 proc
    fld  x
    fmul y                    
    fmul three              
    fld  y
    fmul two                   
    faddp st(1), st            

    fld  x
    fmul x                    
    fld  y
    fmul y                    
    fmul two                  
    faddp st(1), st            
    fadd one                   

    fdivp st(1), st             
    ret
Branch2 endp


Branch3 proc
    fld  x
    fmul five                  
    fld  y
    fmul y                    
    fmul three                 
    fsubp st(1), st            
    fadd seven                 
    ret
Branch3 endp

CalcFunc proc
    fld  x
    fadd y                     

    fcom two                   
    fstsw ax
    sahf
    ja  cf_b1                  

    fcom minus10              
    fstsw ax
    sahf
    jb  cf_b2                  
    jmp cf_b3                  

cf_b1:
    fstp st(0)                 
    mov dx, offset msgB1
    call PrintStr
    call Branch1
    ret
cf_b2:
    fstp st(0)
    mov dx, offset msgB2
    call PrintStr
    call Branch2
    ret
cf_b3:
    fstp st(0)
    mov dx, offset msgB3
    call PrintStr
    call Branch3
    ret
CalcFunc endp


start:
    mov ax, @data
    mov ds, ax
    finit

    mov dx, offset msgX
    call PrintStr
    call ReadReal
    fstp x

    mov dx, offset msgY
    call PrintStr
    call ReadReal
    fstp y

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