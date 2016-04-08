@echo off
setlocal
cd /d %~dp0
powershell -ExecutionPolicy UnRestricted ./imgur_script.ps1 '%*'
rem -WindowStyle Hidden 
endlocal
