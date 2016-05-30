@echo off
setlocal
cd /d %~dp0
powershell -ExecutionPolicy UnRestricted -WindowStyle Hidden ./imgur_script.ps1 '%*'
endlocal
