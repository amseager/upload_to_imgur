@echo off
setlocal
cd /d %~dp0
powershell -ExecutionPolicy UnRestricted -WindowStyle Hidden ./create_sendto_shortcut.ps1
endlocal