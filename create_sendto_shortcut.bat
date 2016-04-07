@echo off
setlocal
cd /d %~dp0
powershell -ExecutionPolicy UnRestricted -WindowStyle Hidden ./src/create_sendto_shortcut.ps1
endlocal