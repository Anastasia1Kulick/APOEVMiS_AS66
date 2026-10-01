; Laboratory work 2, variant 3. MASM, Win32, Windows-1251.
; Input: 1..100 characters followed by a period. The period is not stored.
; No global variables: all writable state belongs to procedure stack frames.

.386
.model flat, stdcall
option casemap:none

MAX_TEXT_LENGTH EQU 100
STD_INPUT_HANDLE EQU -10
STD_OUTPUT_HANDLE EQU -11
RUSSIAN_CODE_PAGE EQU 1251

GetStdHandle PROTO STDCALL :DWORD
SetConsoleCP PROTO STDCALL :DWORD
SetConsoleOutputCP PROTO STDCALL :DWORD
ReadFile PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
WriteFile PROTO STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ExitProcess PROTO STDCALL :DWORD

includelib kernel32.lib

.const
introMsg BYTE "Laboratory work 2 - variant 3", 13, 10, "Condition: the text begins and ends with a Latin letter.", 13, 10, "Rule: replace each uppercase Russian letter with its alphabet index mod 10.", 13, 10
promptMsg BYTE "Enter 1..100 characters, then a period: "
trueMsg BYTE 13, 10, "Condition is true.", 13, 10
falseMsg BYTE 13, 10, "Condition is false. Text is not changed.", 13, 10
resultMsg BYTE "Result: "
newLine BYTE 13, 10
emptyMsg BYTE 13, 10, "Input is not text: it is empty.", 13, 10
longMsg BYTE 13, 10, "Input is not text: longer than 100 characters.", 13, 10
invalidMsg BYTE 13, 10, "Input is not text: a period is required before Enter/EOF.", 13, 10

.code

; Write exactly count bytes, including when stdout is redirected.
PrintBytes PROC outputHandle:DWORD, address:DWORD, count:DWORD
    LOCAL bytesWritten:DWORD
    invoke WriteFile, outputHandle, address, count, ADDR bytesWritten, 0
    ret
PrintBytes ENDP

; Read one byte at a time to detect overlength input without a variable-size buffer.
; EAX: 0 = valid, 1 = empty, 2 = too long, 3 = missing period/invalid control.
ReadText PROC USES esi, inputHandle:DWORD, buffer:DWORD, textLength:DWORD
    LOCAL currentByte:BYTE
    LOCAL bytesRead:DWORD
    LOCAL currentLength:DWORD

    mov currentLength, 0
read_next:
    invoke ReadFile, inputHandle, ADDR currentByte, 1, ADDR bytesRead, 0
    test eax, eax
    jz invalid_input
    cmp bytesRead, 1
    jne invalid_input

    mov al, currentByte
    cmp al, '.'
    je found_period
    cmp al, 32
    jb invalid_input
    cmp currentLength, MAX_TEXT_LENGTH
    jae over_limit

    mov esi, buffer
    mov edx, currentLength
    mov BYTE PTR [esi + edx], al
    inc currentLength
    jmp read_next

found_period:
    cmp currentLength, 0
    je empty_input
    mov esi, buffer
    mov edx, currentLength
    mov BYTE PTR [esi + edx], 0
    mov esi, textLength
    mov DWORD PTR [esi], edx
    xor eax, eax
    ret

empty_input:
    mov eax, 1
    ret
over_limit:
    mov eax, 2
    ret
invalid_input:
    mov eax, 3
    ret
ReadText ENDP

; EAX = 1 if the low byte of value is A-Z or a-z, otherwise EAX = 0.
IsLatinLetter PROC value:DWORD
    mov eax, value
    cmp al, 'A'
    jb not_latin
    cmp al, 'Z'
    jbe latin
    cmp al, 'a'
    jb not_latin
    cmp al, 'z'
    ja not_latin
latin:
    mov eax, 1
    ret
not_latin:
    xor eax, eax
    ret
IsLatinLetter ENDP

; Separate condition-checking procedure. EAX = 1 for true, 0 for false.
CheckCondition PROC USES esi ebx, buffer:DWORD, textLength:DWORD
    mov esi, buffer
    mov ebx, textLength
    test ebx, ebx
    jz condition_false
    movzx eax, BYTE PTR [esi]
    invoke IsLatinLetter, eax
    test eax, eax
    jz condition_false
    dec ebx
    movzx eax, BYTE PTR [esi + ebx]
    invoke IsLatinLetter, eax
    ret
condition_false:
    xor eax, eax
    ret
CheckCondition ENDP

; CP1251 uppercase А..Я = C0h..DFh; Ё = A8h. Alphabet includes Ё
; between Е and Ж, so letters Ж..Я have an index one greater than
; their position in the contiguous code-page range.
TransformText PROC USES esi ebx, buffer:DWORD, textLength:DWORD
    mov esi, buffer
    mov ecx, textLength
    jecxz transformation_done
next_character:
    mov bl, BYTE PTR [esi]
    cmp bl, 0A8h
    je letter_yo
    cmp bl, 0C0h
    jb keep_character
    cmp bl, 0DFh
    ja keep_character

    movzx eax, bl
    sub eax, 0C0h
    inc eax
    cmp bl, 0C6h                 ; Ж and subsequent letters follow Ё.
    jb ordinal_ready
    inc eax
ordinal_ready:
    xor edx, edx
    mov ebx, 10
    div ebx                      ; EDX = alphabet index modulo 10.
    add dl, '0'
    mov BYTE PTR [esi], dl
    jmp keep_character

letter_yo:
    mov BYTE PTR [esi], '7'
keep_character:
    inc esi
    loop next_character
transformation_done:
    ret
TransformText ENDP

start PROC
    LOCAL textBuffer[MAX_TEXT_LENGTH + 1]:BYTE
    LOCAL textLength:DWORD
    LOCAL inputHandle:DWORD
    LOCAL outputHandle:DWORD

    invoke SetConsoleCP, RUSSIAN_CODE_PAGE
    invoke SetConsoleOutputCP, RUSSIAN_CODE_PAGE
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov inputHandle, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax

    ; 1. Input.
    invoke PrintBytes, outputHandle, OFFSET introMsg, SIZEOF introMsg
    invoke PrintBytes, outputHandle, OFFSET promptMsg, SIZEOF promptMsg
    invoke ReadText, inputHandle, ADDR textBuffer, ADDR textLength
    cmp eax, 1
    je show_empty
    cmp eax, 2
    je show_long
    cmp eax, 3
    je show_invalid

    ; 2. Check the variant condition.
    invoke CheckCondition, ADDR textBuffer, textLength
    test eax, eax
    jz show_false
    invoke PrintBytes, outputHandle, OFFSET trueMsg, SIZEOF trueMsg

    ; 3. Transform the accepted text in place.
    invoke TransformText, ADDR textBuffer, textLength

    ; 4. Print the result.
    invoke PrintBytes, outputHandle, OFFSET resultMsg, SIZEOF resultMsg
    invoke PrintBytes, outputHandle, ADDR textBuffer, textLength
    invoke PrintBytes, outputHandle, OFFSET newLine, SIZEOF newLine
    invoke ExitProcess, 0

show_false:
    invoke PrintBytes, outputHandle, OFFSET falseMsg, SIZEOF falseMsg
    invoke ExitProcess, 0
show_empty:
    invoke PrintBytes, outputHandle, OFFSET emptyMsg, SIZEOF emptyMsg
    invoke ExitProcess, 1
show_long:
    invoke PrintBytes, outputHandle, OFFSET longMsg, SIZEOF longMsg
    invoke ExitProcess, 1
show_invalid:
    invoke PrintBytes, outputHandle, OFFSET invalidMsg, SIZEOF invalidMsg
    invoke ExitProcess, 1
    ret
start ENDP

END start
