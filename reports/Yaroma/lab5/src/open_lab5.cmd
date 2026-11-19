@echo off
set "WIRESHARK_CONFIG_DIR=D:\WiresharkPortable\Data\settings"
set "TEMP=D:\CodexTools\tmp"
set "TMP=D:\CodexTools\tmp"
if not exist "D:\WiresharkPortable\App\Wireshark\Wireshark.exe" (
  echo Wireshark Portable was not found on drive D.
  pause
  exit /b 1
)
start "" "D:\WiresharkPortable\App\Wireshark\Wireshark.exe" -r "%~dp0huawei.pcapng"
