.686
.model flat, c

.data
; ��������� ��� ������� 1 (�������������)
c_1    dd 1
c_2    dd 2
c_3    dd 3
c_4    dd 4
c_5    dd 5
c_9    dd 9
c_m5   dd -5

; ��������� ��� ������� 2 (������������/Real)
c_1_r  dd 1.0
c_2_r  dd 2.0
c_3_r  dd 3.0
c_4_r  dd 4.0
c_5_r  dd 5.0
c_9_r  dd 9.0
c_m5_r dd -5.0

; ���������� ���������� ��� �������� ������� �� ���������� ��������
; (������� FPU ������� �������� ������ ������ �� ������)
global_x   dd 0
global_y   dd 0
global_ptr dd 0

global_x_r dd 0.0
global_y_r dd 0.0

.code


; ����� 1: 5x + 2xy + 1
branch1_int PROC
    fild dword ptr [global_x]  ; ��������� ����� x
    fimul dword ptr [c_5]      ; st(0) = 5x

    fild dword ptr [global_x]  
    fimul dword ptr [global_y] 
    fimul dword ptr [c_2]      ; st(0) = 2xy, st(1) = 5x
    
    faddp st(1), st(0)         ; st(0) = 5x + 2xy
    fiadd dword ptr [c_1]      ; st(0) = 5x + 2xy + 1
    
    mov eax, [global_ptr]
    fistp dword ptr [eax]      ; ��������� ��� ����� � �����������
    ret
branch1_int ENDP

; ����� 2: (2xy + 3) / (y^2 + 4)
branch2_int PROC
    fild dword ptr [global_x]
    fimul dword ptr [global_y]
    fimul dword ptr [c_2]
    fiadd dword ptr [c_3]      ; st(0) = ��������� (2xy + 3)

    fild dword ptr [global_y]
    fimul dword ptr [global_y]
    fiadd dword ptr [c_4]      ; st(0) = ����������� (y^2 + 4), st(1) = ���������

    fdivp st(1), st(0)         ; st(0) = ��������� / �����������

    mov eax, [global_ptr]
    fistp dword ptr [eax]
    ret
branch2_int ENDP

; ����� 3: 3x^2 - 2y^2 + 1
branch3_int PROC
    fild dword ptr [global_x]
    fimul dword ptr [global_x]
    fimul dword ptr [c_3]      ; st(0) = 3x^2
    
    fild dword ptr [global_y]
    fimul dword ptr [global_y]
    fimul dword ptr [c_2]      ; st(0) = 2y^2, st(1) = 3x^2
    
    fsubp st(1), st(0)         ; st(0) = 3x^2 - 2y^2
    fiadd dword ptr [c_1]      ; st(0) = 3x^2 - 2y^2 + 1
    
    mov eax, [global_ptr]
    fistp dword ptr [eax]
    ret
branch3_int ENDP

; ������� ������� ������� 1
calculate_int PROC x:DWORD, y:DWORD, res_ptr:DWORD
    ; �������� ��������� � ���������� ������ ��� ���������� �������� FPU
    mov eax, x
    mov [global_x], eax
    mov eax, y
    mov [global_y], eax
    mov eax, res_ptr
    mov [global_ptr], eax

    ; �������� ������� x + y > 9
    fild dword ptr [global_x]
    fiadd dword ptr [global_y] 
    ficomp dword ptr [c_9]     ; ���������� st(0) � 9 � �����������
    fnstsw ax                  ; �������� ����� FPU � ������� AX
    sahf                       ; ��������� � ����������� ����� ����������
    ja do_b1_int

    ; �������� ������� x + y < -5
    fild dword ptr [global_x]
    fiadd dword ptr [global_y]
    ficomp dword ptr [c_m5]
    fnstsw ax
    sahf
    jb do_b2_int

    ; ����� (�� -5 �� 9) ����� 3
    call branch3_int
    jmp end_int

do_b1_int:
    call branch1_int
    jmp end_int

do_b2_int:
    call branch2_int

end_int:
    ret
calculate_int ENDP


; ����� 1: 5x + 2xy + 1
branch1_real PROC
    fld dword ptr [global_x_r] ; ��������� float x
    fmul dword ptr [c_5_r]      

    fld dword ptr [global_x_r]
    fmul dword ptr [global_y_r]
    fmul dword ptr [c_2_r]      
    
    faddp st(1), st(0)          
    fadd dword ptr [c_1_r]      
    
    mov eax, [global_ptr]
    fstp dword ptr [eax]       ; ��������� ��� float
    ret
branch1_real ENDP

; ����� 2: (2xy + 3) / (y^2 + 4)
branch2_real PROC
    fld dword ptr [global_x_r]
    fmul dword ptr [global_y_r]
    fmul dword ptr [c_2_r]
    fadd dword ptr [c_3_r]      

    fld dword ptr [global_y_r]
    fmul dword ptr [global_y_r]
    fadd dword ptr [c_4_r]      

    fdivp st(1), st(0)          

    mov eax, [global_ptr]
    fstp dword ptr [eax]
    ret
branch2_real ENDP

; ����� 3: 3x^2 - 2y^2 + 1
branch3_real PROC
    fld dword ptr [global_x_r]
    fmul dword ptr [global_x_r]
    fmul dword ptr [c_3_r]      
    
    fld dword ptr [global_y_r]
    fmul dword ptr [global_y_r]
    fmul dword ptr [c_2_r]      
    
    fsubp st(1), st(0)          
    fadd dword ptr [c_1_r]      
    
    mov eax, [global_ptr]
    fstp dword ptr [eax]
    ret
branch3_real ENDP

; ������� ������� ������� 2
calculate_real PROC x:DWORD, y:DWORD, res_ptr:DWORD
    ; ��������
    mov eax, x
    mov [global_x_r], eax
    mov eax, y
    mov [global_y_r], eax
    mov eax, res_ptr
    mov [global_ptr], eax

    ; �������� ������� x + y > 9
    fld dword ptr [global_x_r]
    fadd dword ptr [global_y_r]
    fcomp dword ptr [c_9_r]
    fnstsw ax
    sahf
    ja do_b1_real

    ; �������� ������� x + y < -5
    fld dword ptr [global_x_r]
    fadd dword ptr [global_y_r]
    fcomp dword ptr [c_m5_r]
    fnstsw ax
    sahf
    jb do_b2_real

    ; ����� (�� -5 �� 9) ����� 3
    call branch3_real
    jmp end_real

do_b1_real:
    call branch1_real
    jmp end_real

do_b2_real:
    call branch2_real

end_real:
    ret
calculate_real ENDP
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