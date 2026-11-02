; Lab 3, variant 12. Entire application is MASM x86, without C/C++ runtime.
.386
.model flat, stdcall
option casemap:none
include unicode_io.inc
include remove_russian_words.inc

INITIAL_CAPACITY EQU 256
LINE_OK EQU 0
LINE_BAD_ENCODING EQU 1
LINE_NO_MEMORY EQU 2

GetStdHandle PROTO :DWORD
GetConsoleMode PROTO :DWORD, :PTR DWORD
SetConsoleOutputCP PROTO :DWORD
GetProcessHeap PROTO
HeapAlloc PROTO :DWORD, :DWORD, :DWORD
HeapReAlloc PROTO :DWORD, :DWORD, :DWORD, :DWORD
HeapFree PROTO :DWORD, :DWORD, :DWORD
ExitProcess PROTO :DWORD

.const
msgHeader BYTE 'АПО ЭВМиС. Лабораторная работа №3',13,10
    BYTE 'Ярома А. И. | АС-66 | Вариант 12 | MASM x86',13,10
    BYTE 'Макрос удаляет слова с русскими буквами А-Я, а-я, Ё, ё.',13,10
    BYTE 'Разделитель слов - пробел. Исходные пробелы сохраняются.',13,10
    BYTE 'Введите строку и нажмите Enter (точка - обычный символ):',13,10,0
msgOriginal BYTE 13,10,'Исходная строка: "',0
msgResult BYTE '"',13,10,'Результат: "',0
msgLength BYTE '"',13,10,'Длина результата: ',0
msgRemoved BYTE 13,10,'Удалено слов: ',0
msgEnd BYTE 13,10,0
msgEncoding BYTE 'Ошибка: некорректная кодировка Unicode. Обработка не выполнена.',13,10,0
msgMemory BYTE 'Ошибка: недостаточно памяти для строки. Обработка не выполнена.',13,10,0

.code

; Read a line until Enter or EOF. Dots are ordinary characters.
; Grow the input buffer as needed; no inherited 100-character limit.
ReadLine PROC USES esi edi ebx, pContext:PTR InputContext, hHeap:DWORD,
    ppText:PTR DWORD, pLength:PTR DWORD
    LOCAL capacity:DWORD, character:DWORD
    mov eax, ppText
    mov DWORD PTR [eax], 0
    mov eax, pLength
    mov DWORD PTR [eax], 0
    mov capacity, INITIAL_CAPACITY
    invoke HeapAlloc, hHeap, 0, INITIAL_CAPACITY * 4
    mov esi, eax
    test esi, esi
    jz line_no_memory
    xor edi, edi
line_next:
    invoke ReadCharacter, pContext
    cmp eax, CHAR_EOF
    je line_finished
    cmp eax, CHAR_INVALID
    je line_bad_encoding
    cmp eax, 13
    je line_finished
    cmp eax, 10
    je line_finished
    mov character, eax
    lea edx, [edi + 1]
    cmp edx, capacity
    jb line_store
    mov eax, capacity
    cmp eax, 10000000h
    jae line_no_memory
    shl eax, 1
    mov capacity, eax
    shl eax, 2
    invoke HeapReAlloc, hHeap, 0, esi, eax
    test eax, eax
    jz line_no_memory
    mov esi, eax
line_store:
    mov eax, character
    mov [esi + edi * 4], eax
    inc edi
    jmp line_next
line_finished:
    mov DWORD PTR [esi + edi * 4], 0
    mov eax, ppText
    mov [eax], esi
    mov eax, pLength
    mov [eax], edi
    mov eax, LINE_OK
    ret
line_bad_encoding:
    mov ebx, LINE_BAD_ENCODING
    jmp line_cleanup
line_no_memory:
    mov ebx, LINE_NO_MEMORY
line_cleanup:
    test esi, esi
    jz line_return_error
    invoke HeapFree, hHeap, 0, esi
line_return_error:
    mov eax, ebx
    ret
ReadLine ENDP

ProgramMain PROC
    LOCAL context:InputContext
    LOCAL hOutput:DWORD, hHeap:DWORD, textPointer:DWORD
    LOCAL charCount:DWORD, removedCount:DWORD, status:DWORD
    invoke GetStdHandle, -10
    mov context.handle, eax
    invoke GetConsoleMode, context.handle, ADDR context.mode
    mov context.console, eax
    invoke GetStdHandle, -11
    mov hOutput, eax
    invoke SetConsoleOutputCP, 65001
    invoke GetProcessHeap
    mov hHeap, eax
    invoke WriteMessage, hOutput, ADDR msgHeader
    invoke ReadLine, ADDR context, hHeap, ADDR textPointer, ADDR charCount
    cmp eax, LINE_OK
    jne main_error
    invoke WriteMessage, hOutput, ADDR msgOriginal
    invoke PrintText, hOutput, textPointer, charCount

    ; This is a macro invocation, expanded by MASM here, not a CALL.
    REMOVE_RUSSIAN_WORDS textPointer, charCount, charCount, removedCount

    invoke WriteMessage, hOutput, ADDR msgResult
    invoke PrintText, hOutput, textPointer, charCount
    invoke WriteMessage, hOutput, ADDR msgLength
    invoke PrintUnsigned, hOutput, charCount
    invoke WriteMessage, hOutput, ADDR msgRemoved
    invoke PrintUnsigned, hOutput, removedCount
    invoke WriteMessage, hOutput, ADDR msgEnd
    invoke HeapFree, hHeap, 0, textPointer
    xor eax, eax
    ret
main_error:
    mov status, eax
    mov edx, OFFSET msgMemory
    cmp status, LINE_BAD_ENCODING
    jne main_print_error
    mov edx, OFFSET msgEncoding
main_print_error:
    invoke WriteMessage, hOutput, edx
    mov eax, 1
    ret
ProgramMain ENDP

start:
    invoke ProgramMain
    invoke ExitProcess, eax
END start
