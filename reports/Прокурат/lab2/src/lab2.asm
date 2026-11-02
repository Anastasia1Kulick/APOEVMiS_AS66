.386
.model flat, stdcall
option casemap:none

GetStdHandle   PROTO :DWORD
ReadConsoleA   PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteConsoleA  PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess    PROTO :DWORD

includelib kernel32.lib

STD_INPUT_HANDLE  equ -10
STD_OUTPUT_HANDLE equ -11
MAX_LEN           equ 100

.data
    hIn     dd 0
    hOut    dd 0
    nWrite  dd 0
    nRead   dd 0
    bufLen  dd 0
    buffer  db MAX_LEN + 2 dup(0)

    sPrompt     db "Please type a line (max 100 chars, finish with a dot):", 13, 10
    sPromptLen  equ $ - sPrompt

    sCond       db 13, 10, "Checking rule: at least 3 letters from the Latin alphabet.", 13, 10
    sCondLen    equ $ - sCond

    sOK         db "Rule passed. Uppercase Latin letters are shifted one forward, Z becomes A.", 13, 10
    sOKLen      equ $ - sOK

    sFail       db "Rule failed: fewer than 3 Latin letters were found. No changes made.", 13, 10
    sFailLen    equ $ - sFail

    sEmpty      db "The line is empty. Nothing to process.", 13, 10
    sEmptyLen   equ $ - sEmpty

    sResult     db "Result: "
    sResultLen  equ $ - sResult

    sNewLine    db 13, 10
    sNewLineLen equ $ - sNewLine

    sNoDot      db "The dot was not found at the end. Please try again.", 13, 10
    sNoDotLen   equ $ - sNoDot

.code

;------------------------------------------------------------
; WriteStr: печатает строку
;   edx = адрес, ecx = длина
;------------------------------------------------------------
WriteStr proc uses eax
    push 0
    push offset nWrite
    push ecx
    push edx
    push hOut
    call WriteConsoleA
    ret
WriteStr endp

;------------------------------------------------------------
; checkCondition(text) -> eax = 1, если латинских букв >= 3
; Проверка через вычитание: считаем смещение от 'A' или 'a'
; и смотрим, укладывается ли оно в 0..25.
;------------------------------------------------------------
checkCondition proc uses esi ecx edx, text:DWORD
    mov esi, text
    xor ecx, ecx            ; счётчик букв
    xor edx, edx            ; индекс
ccLoop:
    mov al, [esi + edx]
    test al, al
    jz ccDone

    mov bl, al
    sub bl, 'A'
    cmp bl, 25
    jbe ccLetter

    mov bl, al
    sub bl, 'a'
    cmp bl, 25
    ja ccNext

ccLetter:
    inc ecx
ccNext:
    inc edx
    jmp ccLoop

ccDone:
    xor eax, eax
    cmp ecx, 3
    jl ccRet
    mov eax, 1
ccRet:
    ret
checkCondition endp

;------------------------------------------------------------
; transformText(text): сдвиг прописных латинских букв на 1,
; Z заворачивается в A.
; Используются два указателя: esi — откуда читаем,
; edi — куда пишем (в ту же строку).
;------------------------------------------------------------
transformText proc uses esi edi, text:DWORD
    mov esi, text
    mov edi, text
    xor ecx, ecx
ttLoop:
    mov al, [esi + ecx]
    test al, al
    jz ttDone

    cmp al, 'A'
    jb ttNext
    cmp al, 'Z'
    ja ttNext

    cmp al, 'Z'
    je ttWrap
    inc al
    mov [edi + ecx], al
    jmp ttNext

ttWrap:
    mov al, 'A'
    mov [edi + ecx], al

ttNext:
    inc ecx
    jmp ttLoop

ttDone:
    ret
transformText endp

;------------------------------------------------------------
; Точка входа
;------------------------------------------------------------
start:
    push STD_INPUT_HANDLE
    call GetStdHandle
    mov hIn, eax

    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hOut, eax

    mov edx, offset sPrompt
    mov ecx, sPromptLen
    call WriteStr

    push 0
    push offset nRead
    push MAX_LEN + 1
    push offset buffer
    push hIn
    call ReadConsoleA

    ; ищем точку и меняем её на нуль-терминатор
    mov ecx, nRead
    lea esi, buffer
    xor edx, edx
findLoop:
    cmp edx, ecx
    jge noDot
    cmp byte ptr [esi + edx], '.'
    je foundDot
    inc edx
    jmp findLoop

foundDot:
    mov byte ptr [esi + edx], 0
    mov bufLen, edx
    jmp afterFind

noDot:
    mov edx, offset sNoDot
    mov ecx, sNoDotLen
    call WriteStr
    push 0
    call ExitProcess

afterFind:
    mov edx, offset sCond
    mov ecx, sCondLen
    call WriteStr

    cmp bufLen, 0
    jne notEmpty
    mov edx, offset sEmpty
    mov ecx, sEmptyLen
    call WriteStr
    push 0
    call ExitProcess

notEmpty:
    push offset buffer
    call checkCondition
    add esp, 4
    cmp eax, 0
    je failBranch

    mov edx, offset sOK
    mov ecx, sOKLen
    call WriteStr

    push offset buffer
    call transformText
    add esp, 4

    mov edx, offset sResult
    mov ecx, sResultLen
    call WriteStr

    ; длина преобразованной строки
    lea esi, buffer
    xor ecx, ecx
lenLoop:
    cmp byte ptr [esi + ecx], 0
    je lenDone
    inc ecx
    jmp lenLoop
lenDone:
    mov edx, offset buffer
    call WriteStr

    mov edx, offset sNewLine
    mov ecx, sNewLineLen
    call WriteStr

    push 0
    call ExitProcess

failBranch:
    mov edx, offset sFail
    mov ecx, sFailLen
    call WriteStr
    push 0
    call ExitProcess

end start