
.MODEL SMALL
.STACK 100h

COUNT_CHAR MACRO STR, LEN, CHR, RESULT
    LOCAL M_LOOP, M_SKIP, M_DONE
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    LEA  SI, STR          
    MOV  CX, LEN            
    MOV  DL, CHR              
                                 
                                 
    XOR  BX, BX                  

M_LOOP:
    MOV  AL, [SI]           
    CMP  AL, DL               
    JNE  M_SKIP
    INC  BX                     
M_SKIP:
    INC  SI                       
    LOOP M_LOOP

M_DONE:
    MOV  RESULT, BX               
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
ENDM


.DATA
    
    MAX_LEN     DB 80              
    ACT_LEN     DB ?                
    TEXT_STR    DB 80 DUP('$')       
    STR_LEN_W   DW 0                  

    SEARCH_CHR  DB ?                   
    RES_COUNT   DW 0                     
    MSG_ENTER_STR DB 'Vvedite stroku teksta (do 80 simvolov):', 13, 10, '$'
    MSG_ENTER_CHR DB 13, 10, 'Vvedite iskomiy simvol: $'
    MSG_RESULT    DB 13, 10, 'Kolichestvo vhozhdeniy: $'
    NUM_BUF       DB 6 DUP('$')       
    CRLF          DB 13, 10, '$'


.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    LEA  DX, MSG_ENTER_STR
    MOV  AH, 09h
    INT  21h

    LEA  DX, MAX_LEN          
    MOV  AH, 0Ah
    INT  21h

    LEA  DX, CRLF               
    MOV  AH, 09h
    INT  21h

    
    XOR  AH, AH
    MOV  AL, ACT_LEN
    MOV  STR_LEN_W, AX

    
    LEA  DX, MSG_ENTER_CHR
    MOV  AH, 09h
    INT  21h

    MOV  AH, 01h                
    INT  21h
    MOV  SEARCH_CHR, AL

    COUNT_CHAR TEXT_STR, STR_LEN_W, SEARCH_CHR, RES_COUNT

   
    LEA  DX, MSG_RESULT
    MOV  AH, 09h
    INT  21h

    MOV  AX, RES_COUNT
    CALL NUM_TO_STR
    LEA  DX, NUM_BUF
    MOV  AH, 09h
    INT  21h

    LEA  DX, CRLF
    MOV  AH, 09h
    INT  21h

    
    MOV  AH, 4Ch
    INT  21h
MAIN ENDP


NUM_TO_STR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV  CX, 0            
    MOV  BX, 10           
    CMP  AX, 0
    JNE  CONVERT_LOOP
    MOV  NUM_BUF, '0'
    MOV  NUM_BUF+1, '$'
    JMP  CONVERT_DONE

CONVERT_LOOP:
    CMP  AX, 0
    JE   WRITE_LOOP
    XOR  DX, DX
    DIV  BX               
    PUSH DX                
    INC  CX
    JMP  CONVERT_LOOP

WRITE_LOOP:
    LEA  SI, NUM_BUF
WRITE_DIGITS:
    CMP  CX, 0
    JE   WRITE_END
    POP  DX
    ADD  DL, '0'
    MOV  [SI], DL
    INC  SI
    DEC  CX
    JMP  WRITE_DIGITS
WRITE_END:
    MOV  BYTE PTR [SI], '$'

CONVERT_DONE:
    POP  SI
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
NUM_TO_STR ENDP

END MAIN