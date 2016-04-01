@echo off
setlocal
cd /d %~dp0


set SCRIPT="%TEMP%\%RANDOM%-%RANDOM%-%RANDOM%-%RANDOM%.vbs"

echo dim fso: set fso = CreateObject("Scripting.FileSystemObject")
echo dim CurrentDirectory
echo CurrentDirectory = fso.GetAbsolutePathName(".")
echo dim launcher
echo launcher = fso.BuildPath(CurrentDirectory, "launcher.bat")
echo dim icon
echo icon = fso.BuildPath(CurrentDirectory, "icon.ico")

echo Set oWS = WScript.CreateObject("WScript.Shell") >> %SCRIPT%
echo sLinkFile = "%USERPROFILE%\AppData\Roaming\Microsoft\Windows\SendTo\Upload to Imgur1.lnk" >> %SCRIPT%
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> %SCRIPT%


echo oLink.TargetPath = launcher >> %SCRIPT%
echo oLink.IconLocation = icon >> %SCRIPT%

echo oLink.Save >> %SCRIPT%

cscript /nologo %SCRIPT%
del %SCRIPT%

pause