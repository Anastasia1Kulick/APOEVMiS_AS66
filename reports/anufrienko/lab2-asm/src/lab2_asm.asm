; lab2_asm.asm
; Лаб. №2 (ассемблер, обработка символьных данных). Вариант 1.
;
; Условие (помечено "с.к." — требует строковых команд с префиксом повторения):
;     текст оканчивается прописной латинской буквой, которая
;     больше нигде в тексте не встречается.
;
; Правило преобразования (применяется только если условие истинно):
;     каждая ненулевая цифра заменяется на соответствующую строчную
;     латинскую букву: 1->a, 2->b, ..., 9->i. Цифра 0 не трогается.
;
; extern "C" int  CheckConditionAsm(const char* text, int length);
; extern "C" void TransformTextAsm(char* text, int length);
;
; Платформа проекта — x86 (Win32), сборка через ml.exe.
; Предполагается length >= 1 (пустой/слишком длинный текст отсекается в main.cpp).

.386
.MODEL FLAT, C
.CODE

; -----------------------------------------------------------------
; int CheckConditionAsm(const char* text, int length)
; Возвращает 1 (истина) или 0 (ложь) в eax.
; -----------------------------------------------------------------
PUBLIC CheckConditionAsm
CheckConditionAsm PROC
    push ebp
    mov  ebp, esp
    push esi
    push edi

    mov esi, [ebp+8]         ; esi = text
    mov ecx, [ebp+12]        ; ecx = length

    mov edi, esi
    add edi, ecx
    dec edi                   ; edi -> text[length-1] — последний символ текста

    mov al, [edi]              ; al = последний символ

    cmp al, 'A'                 ; это вообще прописная латинская буква A..Z?
    jb  CondFalse
    cmp al, 'Z'
    ja  CondFalse

    cmp ecx, 1
    je  CondTrue                 ; в тексте только эта одна буква — повторов быть не может, условие истинно

    mov edi, esi                 ; снова edi -> начало текста, для поиска повтора
    mov ecx, [ebp+12]
    dec ecx                       ; ищем среди первых (length-1) символов — последний это сама буква, его не считаем
    cld                            ; df=0 — поиск в направлении возрастания адресов
    repne scasb                    ; пока [edi] != al и ecx > 0: сравнить al с [edi], edi++, ecx--

    je CondFalse                   ; если остановились из-за совпадения (zf=1) — буква встретилась повторно, условие ложно

CondTrue:
    mov eax, 1
    jmp CondDone
CondFalse:
    xor eax, eax
CondDone:
    pop edi
    pop esi
    pop ebp
    ret
CheckConditionAsm ENDP


; -----------------------------------------------------------------
; void TransformTextAsm(char* text, int length)
; -----------------------------------------------------------------
PUBLIC TransformTextAsm
TransformTextAsm PROC
    push ebp
    mov  ebp, esp
    push esi

    mov esi, [ebp+8]          ; esi = text
    mov ecx, [ebp+12]         ; ecx = length

TransformLoop:
    mov al, [esi]
    cmp al, '1'
    jb  SkipChar
    cmp al, '9'
    ja  SkipChar
    add al, 48                  ; '1'(0x31)+48 = 0x61 = 'a' ... '9'(0x39)+48 = 0x69 = 'i'
    mov [esi], al
SkipChar:
    inc esi
    dec ecx
    jnz TransformLoop

    pop esi
    pop ebp
    ret
TransformTextAsm ENDP

END