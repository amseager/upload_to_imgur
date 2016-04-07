$CurrentDirectory = [environment]::CurrentDirectory;
$TargetFile = "{0}\src\launcher.bat" -f $CurrentDirectory;
$Icon = "{0}\src\icon.ico" -f $CurrentDirectory;

$ShortcutFile = "$env:APPDATA\Microsoft\Windows\SendTo\Imgur.lnk";
$WScriptShell = New-Object -ComObject WScript.Shell;
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile);
$Shortcut.TargetPath = $TargetFile;
$Shortcut.IconLocation = "{0},0" -f $Icon
$Shortcut.Save();

$Duration = 10000;
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null            
$balloon = New-Object System.Windows.Forms.NotifyIcon                    
$balloon.BalloonTipIcon = "Info"                       
$balloon.BalloonTipTitle = '"Upload to Imgur" link was created'   
$balloon.BalloonTipText = 'Select image files, perform right-click and choose "SendTo" -> "Imgur" to upload'    
$balloon.Icon = $Icon     
$balloon.Visible = $true  
$balloon.ShowBalloonTip($Duration)  
Start-Sleep -Milliseconds $Duration;
$balloon.Dispose()           