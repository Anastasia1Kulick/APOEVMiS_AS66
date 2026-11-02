; lab2_asm.asm
; Лабораторная работа №2 (ассемблер, обработка символьных данных). Вариант 9.
; Куган Н. Л., АС-66.
;
; Условие:
;     за каждой цифрой текста идёт строчная латинская буква (a..z).
;
; Правило преобразования (применяется только если условие истинно):
;     каждая прописная русская буква (кодировка CP1251, 0C0h..0DFh)
;     заменяется симметричной ей в алфавите: А<->Я, Б<->Ю, ...
;
; extern "C" int  CheckConditionAsm(const char* text, int len);
; extern "C" void TransformTextAsm(char* text, int len);
;
; Платформа проекта - x86 (Win32), сборка через ml.exe.

.386
.MODEL FLAT, C
.CODE

; -----------------------------------------------------------------
; int CheckConditionAsm(const char* text, int len)
; Возвращает 1 (истина) или 0 (ложь) в eax.
; -----------------------------------------------------------------
PUBLIC CheckConditionAsm
CheckConditionAsm PROC
    push    ebp
    mov     ebp, esp
    push    esi

    mov     esi, [ebp+8]         ; esi = text
    mov     ecx, [ebp+12]        ; ecx = len
cc_loop:
    test    ecx, ecx
    jz      cc_true              ; текст закончился - нарушений нет
    mov     al, [esi]
    inc     esi
    dec     ecx
    cmp     al, 30h              ; '0'
    jb      cc_loop
    cmp     al, 39h              ; '9'
    ja      cc_loop              ; не цифра - берём следующий символ

    test    ecx, ecx
    jz      cc_false             ; цифра - последний символ, после неё буквы нет
    mov     al, [esi]            ; al = символ сразу после цифры
    cmp     al, 61h              ; 'a'
    jb      cc_false
    cmp     al, 7Ah              ; 'z'
    ja      cc_false
    jmp     cc_loop              ; за цифрой строчная латинская - проверяем дальше

cc_true:
    mov     eax, 1
    jmp     cc_end
cc_false:
    xor     eax, eax
cc_end:
    pop     esi
    pop     ebp
    ret
CheckConditionAsm ENDP


; -----------------------------------------------------------------
; void TransformTextAsm(char* text, int len)
; -----------------------------------------------------------------
PUBLIC TransformTextAsm
TransformTextAsm PROC
    push    ebp
    mov     ebp, esp
    push    esi

    mov     esi, [ebp+8]         ; esi = text
    mov     ecx, [ebp+12]        ; ecx = len
tt_loop:
    test    ecx, ecx
    jz      tt_done
    mov     al, [esi]
    cmp     al, 0C0h             ; 'А' в CP1251
    jb      tt_next
    cmp     al, 0DFh             ; 'Я' в CP1251
    ja      tt_next
    sub     al, 0C0h             ; al = номер буквы в алфавите (0..31)
    neg     al
    add     al, 0DFh             ; al = 0DFh - номер = симметричная буква
    mov     [esi], al
tt_next:
    inc     esi
    dec     ecx
    jmp     tt_loop
tt_done:
    pop     esi
    pop     ebp
    ret
TransformTextAsm ENDP

END
