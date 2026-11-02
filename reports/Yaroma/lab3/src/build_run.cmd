@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "lab_msbuild="
set "lab_vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%lab_vswhere%" (
    for /f "usebackq delims=" %%I in (`"%lab_vswhere%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find MSBuild\**\Bin\MSBuild.exe`) do if not defined lab_msbuild set "lab_msbuild=%%I"
)
if not defined lab_msbuild if exist "D:\visual studio\MSBuild\Current\Bin\MSBuild.exe" set "lab_msbuild=D:\visual studio\MSBuild\Current\Bin\MSBuild.exe"
if not defined lab_msbuild (
    echo Visual Studio build tools with MASM were not found.
    pause
    exit /b 1
)
"%lab_msbuild%" "%~dp0Lab3Variant12.sln" /m /t:Build /p:Configuration=Release /p:Platform=x86 /nologo /verbosity:minimal
if errorlevel 1 (
    pause
    exit /b 1
)
"%~dp0build\Win32\Release\Lab3Variant12.exe"
set "lab_exit_code=%errorlevel%"
pause
exit /b %lab_exit_code%
