; Лабораторная работа 3, макроопределения, вариант 15
; Задание: в строке слов заменить знаком & те слова,
; которые заканчиваются на заданную букву.
; Слово это любые символы между пробелами.
.686
.model flat, c
option casemap:none

SPACE_CH EQU 20h            ; код пробела
AMP_CH   EQU 26h            ; код символа &
END_CH   EQU 0              ; ноль в конце строки

; Макрос COPY_SPACES
; Переписывает пробелы, которые стоят подряд, с места чтения (ESI)
; на место записи (EDI), чтобы между словами пробелы не пропадали
COPY_SPACES MACRO
    LOCAL nextCh, done
nextCh:
    cmp byte ptr [esi], SPACE_CH  ; смотрим, пробел ли сейчас
    jne done                      ; если нет, значит началось слово или строка кончилась
    movsb                         ; копируем пробел, оба указателя сдвигаются сами
    jmp nextCh
done:
ENDM

; Макрос FIND_WORD_END
; Двигает ESI вперед, пока не встретится пробел или конец строки.
; В итоге ESI стоит сразу за последней буквой слова
FIND_WORD_END MACRO
    LOCAL nextCh, done
nextCh:
    cmp byte ptr [esi], SPACE_CH  ; дошли до пробела, слово кончилось
    je done
    cmp byte ptr [esi], END_CH    ; или дошли до конца строки
    je done
    inc esi
    jmp nextCh
done:
ENDM

; Макрос COPY_BLOCK
; Копирует байты начиная с адреса from и до адреса to (сам to не входит)
; туда, куда указывает EDI. Используется rep movsb.
; После него ESI оказывается равен to
COPY_BLOCK MACRO from, to
    mov ecx, to                   ; считаем длину куска как to минус from
    sub ecx, from
    mov esi, from                 ; откуда копировать
    rep movsb                     ; копируем ECX байт
ENDM

; Макрос REPLACE_WORDS, основной
; Проходит по строке и каждое слово, у которого последняя буква sym,
; меняет на один символ &. Строка меняется прямо на месте.
; strPtr это адрес строки, sym это буква, count это куда положить
; сколько слов заменили.
; Портит регистры EAX, EBX, ECX, EDX, ESI, EDI
REPLACE_WORDS MACRO strPtr, sym, count
    LOCAL nextWord, keepWord, finish
    cld                           ; идем по строке слева направо
    mov esi, strPtr               ; ESI читает строку
    mov dl, sym                   ; в DL держим нужную букву
    mov edi, esi                  ; EDI пишет результат в ту же строку
    xor eax, eax                  ; в EAX считаем замены, сначала ноль
nextWord:
    COPY_SPACES                   ; сначала переносим пробелы перед словом
    cmp byte ptr [esi], END_CH    ; если строка закончилась, выходим
    je finish
    mov ebx, esi                  ; запоминаем, где слово начинается
    FIND_WORD_END                 ; ищем, где оно заканчивается
    cmp byte ptr [esi-1], dl      ; последняя буква совпала с нужной?
    jne keepWord
    mov byte ptr [edi], AMP_CH    ; совпала, пишем & вместо всего слова
    inc edi
    inc eax
    jmp nextWord
keepWord:
    COPY_BLOCK ebx, esi           ; не совпала, переписываем слово как есть
    jmp nextWord
finish:
    mov byte ptr [edi], END_CH    ; ставим ноль в новом конце строки
    mov count, eax
ENDM

.code
; Процедура для вызова из C++
; int ReplaceWordsEnd(char* str, char letter)
; Возвращает, сколько слов было заменено
ReplaceWordsEnd PROC USES esi edi ebx, pStr:DWORD, letter:DWORD
    mov edx, letter               ; буква оказывается в DL
    REPLACE_WORDS pStr, dl, eax   ; вызываем макрос, ответ останется в EAX
    ret
ReplaceWordsEnd ENDP

END
