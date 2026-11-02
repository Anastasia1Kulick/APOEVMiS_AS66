.686
.model flat, c
option casemap:none
.const
one SDWORD 1
two SDWORD 2
four SDWORD 4
rOne REAL8 1.0
rTwo REAL8 2.0
rFour REAL8 4.0
upperLimit REAL8 15.0
lowerLimit REAL8 -5.0
.code
IntegerUpper PROC x:SDWORD, y:SDWORD
 LOCAL numerator:REAL8
 fild x
 fimul x
 fild y
 fimul two
 faddp st(1),st(0)
 fstp numerator
 fild x
 fimul x
 fild y
 fimul y
 faddp st(1),st(0)
 fiadd one
 fld numerator
 fdivrp st(1),st(0)
 ret
IntegerUpper ENDP
IntegerLower PROC x:SDWORD, y:SDWORD
 LOCAL numerator:REAL8
 fild y
 fimul y
 fisub x
 fstp numerator
 fild x
 fimul x
 fild y
 fimul y
 faddp st(1),st(0)
 fisub one
 fld numerator
 fdivrp st(1),st(0)
 ret
IntegerLower ENDP
IntegerMiddle PROC x:SDWORD, y:SDWORD
 fild x
 fimul x
 fild y
 fimul y
 fimul two
 faddp st(1),st(0)
 fiadd four
 ret
IntegerMiddle ENDP
CalculateInteger PROC x:SDWORD,y:SDWORD,result:DWORD
 mov eax,x
 sub eax,y
 cmp eax,15
 jg integerUpperBranch
 cmp eax,-5
 jl integerLowerBranch
 invoke IntegerMiddle,x,y
 mov eax,3
 jmp saveInteger
integerUpperBranch:
 invoke IntegerUpper,x,y
 mov eax,1
 jmp saveInteger
integerLowerBranch:
 invoke IntegerLower,x,y
 mov eax,2
saveInteger:
 mov edx,result
 fstp QWORD PTR [edx]
 ret
CalculateInteger ENDP
RealUpper PROC x:REAL8,y:REAL8
 LOCAL numerator:REAL8
 fld x
 fmul x
 fld y
 fmul rTwo
 faddp st(1),st(0)
 fstp numerator
 fld x
 fmul x
 fld y
 fmul y
 faddp st(1),st(0)
 fadd rOne
 fld numerator
 fdivrp st(1),st(0)
 ret
RealUpper ENDP
RealLower PROC x:REAL8,y:REAL8
 LOCAL numerator:REAL8
 fld y
 fmul y
 fsub x
 fstp numerator
 fld x
 fmul x
 fld y
 fmul y
 faddp st(1),st(0)
 fsub rOne
 fld numerator
 fdivrp st(1),st(0)
 ret
RealLower ENDP
RealMiddle PROC x:REAL8,y:REAL8
 fld x
 fmul x
 fld y
 fmul y
 fmul rTwo
 faddp st(1),st(0)
 fadd rFour
 ret
RealMiddle ENDP
CalculateReal PROC x:REAL8,y:REAL8,result:DWORD
 fld x
 fsub y
 fcom upperLimit
 fnstsw ax
 sahf
 ja realUpperBranch
 fcom lowerLimit
 fnstsw ax
 sahf
 jb realLowerBranch
 fstp st(0)
 invoke RealMiddle,x,y
 mov eax,3
 jmp saveReal
realUpperBranch:
 fstp st(0)
 invoke RealUpper,x,y
 mov eax,1
 jmp saveReal
realLowerBranch:
 fstp st(0)
 invoke RealLower,x,y
 mov eax,2
saveReal:
 mov edx,result
 fstp QWORD PTR [edx]
 ret
CalculateReal ENDP
END
