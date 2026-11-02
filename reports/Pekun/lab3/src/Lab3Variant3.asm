; Laboratory work 3, variant 3. MASM, Win32, code page 1251.
; The DELETE_AND_COUNT macro removes a chosen character in place and
; counts nonempty sequences separated by spaces in the resulting text.

.386
.model flat, stdcall
option casemap:none

MAX_TEXT_LENGTH EQU 255
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

; Formal parameters: fixed buffer, source length, character to delete,
; resulting length, and number of words in the resulting text.
; LOCAL gives each macro expansion distinct jump labels.
DELETE_AND_COUNT MACRO buffer, sourceLength, targetByte, resultLength, wordCount
    LOCAL scan_next, skip_target, found_space, finish_scan
    pushad
    lea esi, buffer
    mov edi, esi
    mov ecx, sourceLength
    xor ebx, ebx                 ; Number of completed/started words.
    xor edx, edx                 ; 0 = outside a word, 1 = inside a word.
scan_next:
    test ecx, ecx
    jz finish_scan
    mov al, BYTE PTR [esi]
    inc esi
    dec ecx
    cmp al, targetByte
    je skip_target

    mov BYTE PTR [edi], al       ; Compact kept characters in the same buffer.
    inc edi
    cmp al, ' '
    je found_space
    test edx, edx
    jnz scan_next
    inc ebx                      ; First character of a new nonempty word.
    mov edx, 1
    jmp scan_next

found_space:
    xor edx, edx
skip_target:
    jmp scan_next

finish_scan:
    mov BYTE PTR [edi], 0
    mov eax, edi
    lea edx, buffer
    sub eax, edx
    mov resultLength, eax
    mov wordCount, ebx
    popad
ENDM

.const
introMsg BYTE "Laboratory work 3 - variant 3 (MASM macro)", 13, 10
ruleMsg BYTE "Delete one chosen character and count words after deletion.", 13, 10
symbolPrompt BYTE "Character to delete (one character; space is allowed):", 13, 10
textPrompt BYTE "Text (up to 255 characters; Enter finishes input):", 13, 10
resultPrefix BYTE 13, 10, "Result: ["
resultSuffix BYTE "]", 13, 10
wordsPrefix BYTE "Words: "
newLine BYTE 13, 10
symbolError BYTE 13, 10, "Error: enter exactly one character to delete.", 13, 10
textLengthError BYTE 13, 10, "Error: text is too long (maximum 255 characters).", 13, 10
textInputError BYTE 13, 10, "Error: invalid text input.", 13, 10

.code

PrintBytes PROC outputHandle:DWORD, address:DWORD, count:DWORD
    LOCAL bytesWritten:DWORD
    invoke WriteFile, outputHandle, address, count, ADDR bytesWritten, 0
    ret
PrintBytes ENDP

; EAX = 0 on success, 1 if too long, 2 on invalid byte/read error.
; Read until LF; ignore CR so both Windows CRLF and redirected LF work.
ReadLine PROC USES esi, inputHandle:DWORD, buffer:DWORD, maxLength:DWORD, lengthOut:DWORD
    LOCAL inputByte:BYTE
    LOCAL bytesRead:DWORD
    LOCAL used:DWORD
    mov used, 0
read_next:
    invoke ReadFile, inputHandle, ADDR inputByte, 1, ADDR bytesRead, 0
    test eax, eax
    jz invalid_input
    cmp bytesRead, 0
    je complete_line
    mov al, inputByte
    cmp al, 13
    je read_next
    cmp al, 10
    je complete_line
    cmp al, 32
    jb invalid_input
    mov edx, used
    cmp edx, maxLength
    jae too_long
    mov esi, buffer
    mov BYTE PTR [esi + edx], al
    inc used
    jmp read_next

complete_line:
    mov esi, buffer
    mov edx, used
    mov BYTE PTR [esi + edx], 0
    mov esi, lengthOut
    mov DWORD PTR [esi], edx
    xor eax, eax
    ret
too_long:
    mov eax, 1
    ret
invalid_input:
    mov eax, 2
    ret
ReadLine ENDP

; Print a DWORD in decimal without CRT or a variable-sized buffer.
PrintUnsigned PROC USES ebx esi edi, outputHandle:DWORD, value:DWORD
    LOCAL digits[11]:BYTE
    lea esi, digits
    add esi, 11
    mov ebx, 10
    mov eax, value
    xor edi, edi
next_digit:
    xor edx, edx
    div ebx
    dec esi
    add dl, '0'
    mov BYTE PTR [esi], dl
    inc edi
    test eax, eax
    jnz next_digit
    invoke PrintBytes, outputHandle, esi, edi
    ret
PrintUnsigned ENDP

start PROC
    LOCAL targetBuffer[2]:BYTE
    LOCAL textBuffer[MAX_TEXT_LENGTH + 1]:BYTE
    LOCAL targetLength:DWORD
    LOCAL textLength:DWORD
    LOCAL resultLength:DWORD
    LOCAL wordCount:DWORD
    LOCAL targetByte:BYTE
    LOCAL inputHandle:DWORD
    LOCAL outputHandle:DWORD

    invoke SetConsoleCP, RUSSIAN_CODE_PAGE
    invoke SetConsoleOutputCP, RUSSIAN_CODE_PAGE
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov inputHandle, eax
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov outputHandle, eax

    invoke PrintBytes, outputHandle, OFFSET introMsg, SIZEOF introMsg
    invoke PrintBytes, outputHandle, OFFSET ruleMsg, SIZEOF ruleMsg

    invoke PrintBytes, outputHandle, OFFSET symbolPrompt, SIZEOF symbolPrompt
    invoke ReadLine, inputHandle, ADDR targetBuffer, 1, ADDR targetLength
    test eax, eax
    jnz show_symbol_error
    cmp targetLength, 1
    jne show_symbol_error
    mov al, targetBuffer[0]
    mov targetByte, al

    invoke PrintBytes, outputHandle, OFFSET textPrompt, SIZEOF textPrompt
    invoke ReadLine, inputHandle, ADDR textBuffer, MAX_TEXT_LENGTH, ADDR textLength
    cmp eax, 1
    je show_text_length_error
    cmp eax, 2
    je show_text_input_error

    ; This call expands to the full deletion and counting instruction block.
    DELETE_AND_COUNT textBuffer, textLength, targetByte, resultLength, wordCount

    invoke PrintBytes, outputHandle, OFFSET resultPrefix, SIZEOF resultPrefix
    invoke PrintBytes, outputHandle, ADDR textBuffer, resultLength
    invoke PrintBytes, outputHandle, OFFSET resultSuffix, SIZEOF resultSuffix
    invoke PrintBytes, outputHandle, OFFSET wordsPrefix, SIZEOF wordsPrefix
    invoke PrintUnsigned, outputHandle, wordCount
    invoke PrintBytes, outputHandle, OFFSET newLine, SIZEOF newLine
    invoke ExitProcess, 0

show_symbol_error:
    invoke PrintBytes, outputHandle, OFFSET symbolError, SIZEOF symbolError
    invoke ExitProcess, 1
show_text_length_error:
    invoke PrintBytes, outputHandle, OFFSET textLengthError, SIZEOF textLengthError
    invoke ExitProcess, 1
show_text_input_error:
    invoke PrintBytes, outputHandle, OFFSET textInputError, SIZEOF textInputError
    invoke ExitProcess, 1
    ret
start ENDP

END start
