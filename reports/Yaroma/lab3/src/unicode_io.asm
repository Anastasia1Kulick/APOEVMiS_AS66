; Shared Unicode I/O, MASM x86. No text-processing algorithm in this module.
.386
.model flat, stdcall
option casemap:none
include unicode_io.inc

ReadFile PROTO :DWORD, :DWORD, :DWORD, :PTR DWORD, :DWORD
ReadConsoleW PROTO :DWORD, :DWORD, :DWORD, :PTR DWORD, :DWORD
WriteFile PROTO :DWORD, :DWORD, :DWORD, :PTR DWORD, :DWORD

PUBLIC ReadCharacter, WriteMessage, PrintText, PrintUnsigned
.code
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
END
