@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "msbuild_path="
set "vswhere_path=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"

if exist "%vswhere_path%" (
    for /f "usebackq delims=" %%I in (`"%vswhere_path%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find MSBuild\**\Bin\MSBuild.exe`) do if not defined msbuild_path set "msbuild_path=%%I"
)
if not defined msbuild_path if exist "D:\visual studio\MSBuild\Current\Bin\MSBuild.exe" set "msbuild_path=D:\visual studio\MSBuild\Current\Bin\MSBuild.exe"
if not defined msbuild_path goto missing_tools

echo Building Lab1Variant12: Release / Win32...
"%msbuild_path%" "%~dp0Lab1Variant12.sln" /m /t:Build /p:Configuration=Release /p:Platform=Win32 /nologo /verbosity:minimal
if errorlevel 1 goto build_failed

echo.
"%~dp0build\Win32\Release\Lab1Variant12.exe" %*
set "run_exit_code=%errorlevel%"
echo.
pause
exit /b %run_exit_code%

:missing_tools
echo Visual Studio C++ build tools were not found.
echo Install the Desktop development with C++ workload, then try again.
echo.
pause
exit /b 1

:build_failed
echo.
echo Build failed. Check the error messages above.
pause
exit /b 1
