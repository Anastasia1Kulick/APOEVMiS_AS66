; Lab 2, variant 12. All executable program logic is MASM x86.
; Win32 API supplies console/file I/O; neither C++ nor a CRT is linked.
.386
.model flat, stdcall
option casemap:none

MAX_LENGTH EQU 100
INPUT_OK EQU 0
INPUT_EMPTY EQU 1
INPUT_LONG EQU 2
INPUT_NO_PERIOD EQU 3
INPUT_BAD_ENCODING EQU 4
CHAR_EOF EQU -1
CHAR_INVALID EQU -2

GetStdHandle PROTO :DWORD
GetConsoleMode PROTO :DWORD, :PTR DWORD
SetConsoleOutputCP PROTO :DWORD
ReadFile PROTO :DWORD, :DWORD, :DWORD, :PTR DWORD, :DWORD
ReadConsoleW PROTO :DWORD, :DWORD, :DWORD, :PTR DWORD, :DWORD
WriteFile PROTO :DWORD, :DWORD, :DWORD, :PTR DWORD, :DWORD
ExitProcess PROTO :DWORD
CheckConditionAsm PROTO C :PTR DWORD, :DWORD, :PTR DWORD, :PTR DWORD
RotateLeftAsm PROTO C :PTR DWORD, :DWORD

InputContext STRUCT
    handle DWORD ?
    console DWORD ?
    mode DWORD ?
    skipLF DWORD ?
InputContext ENDS

; Immutable messages, not global variables. Source file encoding is UTF-8.
.const
msgHeader BYTE 'АПО ЭВМиС. Лабораторная работа №2',13,10
    BYTE 'Ярома А. И. | АС-66 | Вариант 12 | MASM x86',13,10
    BYTE 'Условие: число строчных русских букв равно числу цифр.',13,10
    BYTE 'Правило: циклический сдвиг на 3 символа влево.',13,10
    BYTE 'Введите от 1 до 100 символов; завершите точкой и нажмите Enter:',13,10,0
msgOriginal BYTE 13,10,'Исходный текст: "',0
msgLength BYTE '"',13,10,'Длина: ',0
msgCharacters BYTE ' символов',13,10,0
msgLetters BYTE 'Строчных русских букв: ',0
msgDigits BYTE 13,10,'Цифр: ',0
msgFalse BYTE 13,10,'Условие не выполнено. Текст не преобразуется.',13,10,0
msgTrue BYTE 13,10,'Условие выполнено. Сдвиг на 3 символа влево.',13,10,0
msgResult BYTE 'Результат: "',0
msgEnd BYTE '"',13,10,0
msgInvalid BYTE 'Последовательность не является допустимым текстом: ',0
msgEmpty BYTE 'пустой текст.',13,10,0
msgLong BYTE 'больше 100 символов.',13,10,0
msgNoPeriod BYTE 'нет завершающей точки.',13,10,0
msgEncoding BYTE 'ошибка кодировки Unicode.',13,10,0
msgNotConverted BYTE 'Преобразование не выполняется.',13,10,0

.code

; Read one UTF-16 code unit from a console, or one byte from a file/pipe.
; Fixed-size locals only; EAX = unit or CHAR_EOF.
ReadRaw PROC USES esi, pContext:PTR InputContext
    LOCAL unitValue:DWORD, received:DWORD
    mov esi, pContext
    mov unitValue, 0
    cmp [esi].InputContext.console, 0
    je raw_file
    invoke ReadConsoleW, [esi].InputContext.handle, ADDR unitValue, 1, ADDR received, 0
    jmp raw_done
raw_file:
    invoke ReadFile, [esi].InputContext.handle, ADDR unitValue, 1, ADDR received, 0
raw_done:
    test eax, eax
    jz raw_eof
    cmp received, 0
    je raw_eof
    mov eax, unitValue
    ret
raw_eof:
    mov eax, CHAR_EOF
    ret
ReadRaw ENDP

; Decode one Unicode scalar. Console input is UTF-16; redirected input is UTF-8.
; EAX = scalar, CHAR_EOF, or CHAR_INVALID. No text-sized temporary buffer.
ReadCharacter PROC USES esi ebx edi, pContext:PTR InputContext
    LOCAL minimum:DWORD
    mov esi, pContext
    invoke ReadRaw, esi
    cmp eax, CHAR_EOF
    je character_return
    cmp [esi].InputContext.console, 0
    je decode_utf8
    cmp eax, 0D800h
    jb character_return
    cmp eax, 0DBFFh
    ja check_low_surrogate
    sub eax, 0D800h
    shl eax, 10
    mov ebx, eax
    invoke ReadRaw, esi
    cmp eax, 0DC00h
    jb character_invalid
    cmp eax, 0DFFFh
    ja character_invalid
    sub eax, 0DC00h
    lea eax, [eax + ebx + 10000h]
    ret
check_low_surrogate:
    cmp eax, 0DFFFh
    jbe character_invalid
    ret
decode_utf8:
    cmp eax, 80h
    jb character_return
    mov minimum, 80h
    mov edi, 1
    cmp eax, 0C2h
    jb character_invalid
    cmp eax, 0DFh
    jbe utf8_two
    mov minimum, 800h
    mov edi, 2
    cmp eax, 0EFh
    jbe utf8_three
    cmp eax, 0F4h
    ja character_invalid
    mov minimum, 10000h
    mov edi, 3
    and eax, 7
    jmp utf8_continue
utf8_three:
    and eax, 0Fh
    jmp utf8_continue
utf8_two:
    and eax, 1Fh
utf8_continue:
    mov ebx, eax
utf8_next:
    invoke ReadRaw, esi
    mov edx, eax
    and edx, 0FFFFFFC0h
    cmp edx, 80h
    jne character_invalid
    shl ebx, 6
    and eax, 3Fh
    or ebx, eax
    dec edi
    jnz utf8_next
    mov eax, ebx
    cmp eax, minimum
    jb character_invalid
    cmp eax, 10FFFFh
    ja character_invalid
    cmp eax, 0D800h
    jb character_return
    cmp eax, 0DFFFh
    jbe character_invalid
character_return:
    ret
character_invalid:
    mov eax, CHAR_INVALID
    ret
ReadCharacter ENDP

; Stage 1: read/validate. The point is not stored; CRLF is one newline.
; The sole text buffer has a constant capacity of MAX_LENGTH + 1 DWORDs.
ReadText PROC USES esi edi ebx, pContext:PTR InputContext, pText:PTR DWORD, pLength:PTR DWORD
    LOCAL overflow:DWORD
    mov esi, pContext
    mov edi, pText
    xor ebx, ebx
    mov overflow, 0
read_next:
    invoke ReadCharacter, esi
    cmp eax, CHAR_EOF
    je input_no_period
    cmp eax, CHAR_INVALID
    je input_bad_encoding
    cmp [esi].InputContext.skipLF, 0
    je check_newline
    mov [esi].InputContext.skipLF, 0
    cmp eax, 10
    je read_next
check_newline:
    cmp eax, 13
    jne check_period
    mov [esi].InputContext.skipLF, 1
    mov eax, 10
check_period:
    cmp eax, '.'
    je input_finished
    cmp ebx, MAX_LENGTH
    jae input_overflow
    mov [edi + ebx * 4], eax
    inc ebx
    jmp read_next
input_overflow:
    mov overflow, 1
    jmp read_next
input_finished:
    mov eax, INPUT_LONG
    cmp overflow, 0
    jne input_return
    mov eax, INPUT_EMPTY
    test ebx, ebx
    jz input_return
    mov eax, INPUT_OK
    jmp input_return
input_no_period:
    mov eax, INPUT_NO_PERIOD
    jmp input_return
input_bad_encoding:
    mov eax, INPUT_BAD_ENCODING
input_return:
    mov DWORD PTR [edi + ebx * 4], 0
    mov edx, pLength
    mov [edx], ebx
    ret
ReadText ENDP

; Write all bytes, including the case of a partial WriteFile.
WriteAll PROC USES esi ebx, hOutput:DWORD, pBytes:DWORD, byteCount:DWORD
    LOCAL written:DWORD
    mov esi, pBytes
    mov ebx, byteCount
write_more:
    test ebx, ebx
    jz write_success
    invoke WriteFile, hOutput, esi, ebx, ADDR written, 0
    test eax, eax
    jz write_return
    cmp written, 0
    je write_failed
    add esi, written
    sub ebx, written
    jmp write_more
write_failed:
    xor eax, eax
write_return:
    ret
write_success:
    mov eax, 1
    ret
WriteAll ENDP

WriteMessage PROC hOutput:DWORD, pMessage:DWORD
    mov edx, pMessage
    xor ecx, ecx
message_length:
    cmp BYTE PTR [edx + ecx], 0
    je message_write
    inc ecx
    jmp message_length
message_write:
    invoke WriteAll, hOutput, edx, ecx
    ret
WriteMessage ENDP

; Encode one scalar in a fixed four-byte local, then print it.
PrintCharacter PROC USES ebx, hOutput:DWORD, value:DWORD
    LOCAL encoded:DWORD, byteCount:DWORD
    mov eax, value
    lea edx, encoded
    mov byteCount, 1
    cmp eax, 80h
    jb encode_last
    mov byteCount, 2
    cmp eax, 800h
    jb encode_continuations
    mov byteCount, 3
    cmp eax, 10000h
    jb encode_continuations
    mov byteCount, 4
encode_continuations:
    mov ecx, byteCount
    dec ecx
encode_tail:
    mov ebx, eax
    and ebx, 3Fh
    or bl, 80h
    mov [edx + ecx], bl
    shr eax, 6
    dec ecx
    jnz encode_tail
    cmp byteCount, 2
    je encode_head_two
    cmp byteCount, 3
    je encode_head_three
    or eax, 0F0h
    jmp encode_store_head
encode_head_three:
    or eax, 0E0h
    jmp encode_store_head
encode_head_two:
    or eax, 0C0h
encode_store_head:
    mov [edx], al
    jmp encode_write
encode_last:
    mov [edx], al
encode_write:
    invoke WriteAll, hOutput, ADDR encoded, byteCount
    ret
PrintCharacter ENDP

; Stage 4: print the transformed text, without changing the working buffer.
PrintText PROC USES esi ebx, hOutput:DWORD, pText:PTR DWORD, charCount:DWORD
    mov esi, pText
    mov ebx, charCount
print_next:
    test ebx, ebx
    jz print_done
    invoke PrintCharacter, hOutput, DWORD PTR [esi]
    add esi, 4
    dec ebx
    jmp print_next
print_done:
    ret
PrintText ENDP

PrintUnsigned PROC USES ebx edi, hOutput:DWORD, value:DWORD
    LOCAL digits[10]:BYTE
    lea edi, digits[10]
    mov eax, value
    mov ebx, 10
number_next:
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz number_next
    lea ecx, digits[10]
    sub ecx, edi
    invoke WriteAll, hOutput, edi, ecx
    ret
PrintUnsigned ENDP

ProgramMain PROC
    LOCAL text[MAX_LENGTH + 1]:DWORD
    LOCAL context:InputContext
    LOCAL hOutput:DWORD, charLength:DWORD, letters:DWORD, digits:DWORD, status:DWORD
    invoke GetStdHandle, -10
    mov context.handle, eax
    invoke GetConsoleMode, context.handle, ADDR context.mode
    mov context.console, eax
    mov context.skipLF, 0
    invoke GetStdHandle, -11
    mov hOutput, eax
    invoke SetConsoleOutputCP, 65001
    invoke WriteMessage, hOutput, ADDR msgHeader
    invoke ReadText, ADDR context, ADDR text, ADDR charLength
    mov status, eax
    cmp eax, INPUT_OK
    jne main_invalid
    invoke WriteMessage, hOutput, ADDR msgOriginal
    invoke PrintText, hOutput, ADDR text, charLength
    invoke WriteMessage, hOutput, ADDR msgLength
    invoke PrintUnsigned, hOutput, charLength
    invoke WriteMessage, hOutput, ADDR msgCharacters
    ; Stage 2: separate condition procedure.
    invoke CheckConditionAsm, ADDR text, charLength, ADDR letters, ADDR digits
    mov status, eax
    invoke WriteMessage, hOutput, ADDR msgLetters
    invoke PrintUnsigned, hOutput, letters
    invoke WriteMessage, hOutput, ADDR msgDigits
    invoke PrintUnsigned, hOutput, digits
    cmp status, 0
    je main_false
    invoke WriteMessage, hOutput, ADDR msgTrue
    ; Stage 3: separate in-place conversion procedure, uses REP MOVSD.
    invoke RotateLeftAsm, ADDR text, charLength
    invoke WriteMessage, hOutput, ADDR msgResult
    invoke PrintText, hOutput, ADDR text, charLength
    invoke WriteMessage, hOutput, ADDR msgEnd
    xor eax, eax
    ret
main_false:
    invoke WriteMessage, hOutput, ADDR msgFalse
    xor eax, eax
    ret
main_invalid:
    invoke WriteMessage, hOutput, ADDR msgInvalid
    mov edx, OFFSET msgEncoding
    cmp status, INPUT_EMPTY
    je main_empty
    cmp status, INPUT_LONG
    je main_long
    cmp status, INPUT_NO_PERIOD
    je main_no_period
    jmp main_error_message
main_empty:
    mov edx, OFFSET msgEmpty
    jmp main_error_message
main_long:
    mov edx, OFFSET msgLong
    jmp main_error_message
main_no_period:
    mov edx, OFFSET msgNoPeriod
main_error_message:
    invoke WriteMessage, hOutput, edx
    invoke WriteMessage, hOutput, ADDR msgNotConverted
    mov eax, 1
    ret
ProgramMain ENDP

start:
    invoke ProgramMain
    invoke ExitProcess, eax
END start
