; lab1_asm.asm
; Лаб. №1 (ассемблер). Вариант 1: перевернуть строку.
; extern "C" void ReverseStringAsm(char* str);
;
; Платформа проекта в Visual Studio ДОЛЖНА быть x86 (Win32) — .MODEL FLAT
; рассчитан на 32-битный код. Сборка идёт через ml.exe (MASM), не ml64.exe.

.386
.MODEL FLAT, C
.CODE

PUBLIC ReverseStringAsm
ReverseStringAsm PROC
    push ebp
    mov  ebp, esp
    push esi
    push edi

    mov esi, [ebp+8]        ; esi -> начало строки (левый указатель)
    mov edi, esi

FindEnd:                    ; ищем нулевой байт-терминатор
    cmp byte ptr [edi], 0
    je  EndFound
    inc edi
    jmp FindEnd
EndFound:
    dec edi                 ; edi -> последний символ строки (правый указатель)

SwapLoop:
    cmp esi, edi
    jge Done                ; указатели встретились/разминулись — готово

    mov al, [esi]
    mov dl, [edi]
    mov [esi], dl
    mov [edi], al

    inc esi
    dec edi
    jmp SwapLoop

Done:
    pop edi
    pop esi
    pop ebp
    ret
ReverseStringAsm ENDP

END