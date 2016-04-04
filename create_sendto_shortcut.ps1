$CurrentDirectory = [environment]::CurrentDirectory;
$TargetFile = "{0}\launcher.bat" -f $CurrentDirectory;
$Icon = "{0}\icon.ico" -f $CurrentDirectory;
$ShortcutFile = "$env:APPDATA\Microsoft\Windows\SendTo\Upload to Imgur.lnk";
$WScriptShell = New-Object -ComObject WScript.Shell;
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile);
$Shortcut.TargetPath = $TargetFile;
$Shortcut.IconLocation = "{0},0" -f $Icon
$Shortcut.Save();