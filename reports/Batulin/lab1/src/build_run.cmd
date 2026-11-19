@echo off
setlocal
cd /d "%~dp0"
set "LAB_VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%LAB_VSWHERE%" (
  echo Visual Studio Installer was not found. Install Visual Studio with Desktop development with C++.
  exit /b 1
)
set "LAB_VSROOT="
for /f "usebackq delims=" %%I in (`"%LAB_VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "LAB_VSROOT=%%I"
if not defined LAB_VSROOT (
  echo Install the Desktop development with C++ workload.
  exit /b 1
)
call "%LAB_VSROOT%\Common7\Tools\VsDevCmd.bat" -arch=x86 -host_arch=x64 >nul
if errorlevel 1 exit /b 1
msbuild Lab1Variant5.sln /nologo /m /p:Configuration=Release /p:Platform=Win32 /verbosity:minimal
if errorlevel 1 exit /b 1
build\Release\Lab1Variant5.exe %*
exit /b %errorlevel%
