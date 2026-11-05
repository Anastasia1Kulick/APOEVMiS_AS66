.686
.model flat, stdcall
option casemap:none
include numeric_io.inc
getchar PROTO C
strtol PROTO C :PTR BYTE, :PTR DWORD, :SDWORD
strtod PROTO C :PTR BYTE, :PTR DWORD
_errno PROTO C
.code
; Read one complete line. kind=1 -> signed DWORD, kind=2 -> REAL8.
; EAX=0 success, 1 invalid input/EOF/range/line too long. Max 255 bytes.
; The full line is consumed before validation; trailing junk is rejected.
ReadNumber PROC USES esi edi ebx, kind:DWORD, destination:DWORD
    LOCAL buffer[256]:BYTE, endPointer:DWORD, overflow:DWORD
    lea esi, buffer
    xor ebx, ebx
    mov overflow, 0
    invoke fflush, 0
read_loop:
    invoke getchar
    cmp eax, -1
    je line_end
    cmp eax, 10
    je line_end
    test eax, eax
    jz too_long
    cmp ebx, 255
    jae too_long
    mov [esi + ebx], al
    inc ebx
    jmp read_loop
too_long:
    mov overflow, 1
    jmp read_loop
line_end:
    mov BYTE PTR [esi + ebx], 0
    cmp overflow, 0
    jne invalid
    test ebx, ebx
    jz invalid
    invoke _errno
    mov DWORD PTR [eax], 0
    mov edi, destination
    cmp kind, 1
    jne parse_real
    invoke strtol, esi, ADDR endPointer, 10
    mov [edi], eax
    invoke _errno
    cmp DWORD PTR [eax], 0
    jne invalid
    jmp check_tail
parse_real:
    invoke strtod, esi, ADDR endPointer
    fstp REAL8 PTR [edi]
    mov eax, [edi + 4]
    and eax, 7FF00000h
    cmp eax, 7FF00000h
    je invalid
    invoke _errno
    cmp DWORD PTR [eax], 0
    je check_tail
    ; Accept representable subnormals; reject underflow to zero.
    mov eax, [edi + 4]
    and eax, 7FFFFFFFh
    or eax, [edi]
    jz invalid
check_tail:
    mov edx, endPointer
    cmp edx, esi
    je invalid
tail_loop:
    mov al, [edx]
    test al, al
    jz valid
    cmp al, 32
    je tail_next
    cmp al, 9
    jb invalid
    cmp al, 13
    ja invalid
tail_next:
    inc edx
    jmp tail_loop
valid:
    xor eax, eax
    ret
invalid:
    mov eax, 1
    ret
ReadNumber ENDP
END
