@echo off
setlocal
cd /d "%~dp0"
if not exist ..\build mkdir ..\build
cl /nologo /std:c++17 /O2 /W4 /utf-8 /EHsc main.cpp transform.cpp /Fe:..\build\lab1.exe
if errorlevel 1 exit /b 1
..\build\lab1.exe --test
