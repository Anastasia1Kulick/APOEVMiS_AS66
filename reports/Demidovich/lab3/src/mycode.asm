MOVE_CHAR MACRO STR_ADDR, CHAR, LEN
    LOCAL search_loop, found, shift_loop, end_macro
    
    MOV CX, LEN
    LEA DI, STR_ADDR
    MOV AL, CHAR
    MOV SI, DI
    
search_loop:
    CMP [DI], AL
    JE found
    INC DI
    LOOP search_loop
    JMP end_macro

found:
    CMP SI, DI
    JE end_macro
    
    MOV CX, DI
    SUB CX, SI
    MOV BX, DI
    
shift_loop:
    DEC BX
    MOV DL, [BX]
    MOV [BX+1], DL
    LOOP shift_loop
    
    MOV [SI], AL

end_macro:
ENDM

.MODEL SMALL
.STACK 100h

.DATA
    my_string DB 'assembly', '$'
    my_char   DB 'm'
    str_len   DW 8

.CODE
START:
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX

    MOVE_CHAR my_string, my_char, str_len 

    LEA DX, my_string
    MOV AH, 09h
    INT 21h

    MOV AH, 4Ch
    INT 21h
END START
```<FollowUp>