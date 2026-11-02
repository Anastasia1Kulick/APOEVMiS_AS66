; MASM declarations. CRT is used for numeric parsing and printing only.
printf PROTO C :PTR BYTE, :VARARG
fflush PROTO C :DWORD
ReadNumber PROTO :DWORD, :DWORD
EvaluateInteger PROTO :SDWORD, :SDWORD, :PTR REAL8, :PTR DWORD
EvaluateReal PROTO :PTR REAL8, :PTR REAL8, :PTR REAL8, :PTR DWORD
