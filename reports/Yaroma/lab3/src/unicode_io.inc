; Shared declarations for the assembly-only console/file I/O module.
CHAR_EOF EQU -1
CHAR_INVALID EQU -2

InputContext STRUCT
    handle DWORD ?
    console DWORD ?
    mode DWORD ?
InputContext ENDS

ReadCharacter PROTO :PTR InputContext
WriteMessage PROTO :DWORD, :DWORD
PrintText PROTO :DWORD, :PTR DWORD, :DWORD
PrintUnsigned PROTO :DWORD, :DWORD
