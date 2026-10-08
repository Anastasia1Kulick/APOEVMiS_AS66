@echo off
setlocal EnableExtensions DisableDelayedExpansion
if not exist "%~dp0build\Win32\Release\Lab1Variant12.exe" goto missing_program

"%~dp0build\Win32\Release\Lab1Variant12.exe" %*
set "run_exit_code=%errorlevel%"
echo.
pause
exit /b %run_exit_code%

:missing_program
echo The program has not been built yet.
echo Run build_run.cmd once, or build Release / Win32 in Visual Studio.
echo.
pause
exit /b 1
