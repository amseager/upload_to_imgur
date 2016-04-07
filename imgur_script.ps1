Param(
	[String]$files
);
$CurrentDirectory = [environment]::CurrentDirectory;
$Icon = "$CurrentDirectory\icon.ico";

function Get-ResponseText {
	param(
		[parameter(Mandatory=$true)]
		[System.Net.WebRequest] $request
	);
	$response = $request.GetResponse().GetResponseStream();
	$sr = new-object System.IO.StreamReader $response;
	$responseText = $sr.ReadToEnd();
	return $responseText;
}

function Get-RegexMatch {
	param(
		[parameter(Mandatory=$true)] [string] $text,
		[parameter(Mandatory=$true)] [string] $regex
	);
	$found = $text -match $regex;
	if ($found) {$match = $matches[1];};
	return $match;
}

function Get-ContentType {
	param(
		[parameter(Mandatory=$true)] $file
	)
	$contentTypeMap = @{
		".jpg"  = "image/jpeg";
		".jpeg" = "image/jpeg";
		".gif"  = "image/gif";
		".png"  = "image/png";
		".tiff" = "image/tiff";
	};
	$ext = $file.Substring($file.LastIndexOf(".")).ToLower();
	$fileContentType = $contentTypeMap[$ext];
	return $fileContentType;
}

function Get-RequestWithHeaders {
	param(
		[parameter(Mandatory=$true)] [string] $Url,
		[ValidateSet('GET','POST')] [string] $Method = 'GET',
		[bool] $KeepAlive = $true,
		[string] $AutomaticDecompression = "Deflate, GZip",
		[string] $Referer = "http://imgur.com/",
		[string] $UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36 OPR/36.0.2130.32",
		[string] $Accept = "application/json, text/javascript, */*; q=0.01",
		[string] $AcceptEncoding = "lzma, sdch",
		[string] $AcceptLanguage = "ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4",
		[string] $XRequestedWith = "XMLHttpRequest",
		[string] $CacheControl,		
		[string] $ContentType,
		[string] $Cookie,
		[string] $Origin,
		[string] $XImgur
	);
	$request = [System.Net.WebRequest]::Create($url);
	
	$request.Method = $Method;
	$request.KeepAlive = $KeepAlive;
	$request.AutomaticDecompression = $AutomaticDecompression;
	$request.Referer = $Referer;
	$request.UserAgent = $UserAgent;
	$request.Accept = $Accept;
	$request.Headers.Add("Accept-Encoding", $AcceptEncoding);
	$request.Headers.Add("Accept-Language", $AcceptLanguage);
	$request.Headers.Add("X-Requested-With", $XRequestedWith);
	
	if ($ContentType -ne '') 	{$request.ContentType = $ContentType};
	if ($CacheControl -ne '') 	{$request.Headers.Add("Cache-Control", $CacheControl)};
	if ($Cookie -ne '') 		{$request.Headers.Add("Cookie", $Cookie)};
	if ($Origin -ne '') 		{$request.Headers.Add("Origin", $Origin)};
	if ($XImgur -ne '') 		{$request.Headers.Add("X-Imgur", $XImgur)};
	
	return $request;
}

function Set-MultipartFormData {
	param(
		[parameter(Mandatory=$true)] [System.Net.WebRequest] $request,
		[parameter(Mandatory=$true)] [string] $boundary,
		[parameter(Mandatory=$true)] [System.Collections.Specialized.OrderedDictionary]$bodyArgs,
		[parameter(Mandatory=$true)] [string] $file,
		[parameter(Mandatory=$true)] [string] $fileContentType
	);
	$enc = [System.Text.Encoding]::GetEncoding(0);
	$fileDataBytes = [System.IO.File]::ReadAllBytes($file);
	$fileData = $enc.GetString($fileDataBytes);	
	
	$header = "--$boundary";
	$footer = "--$boundary--";
	$contents = New-Object System.Text.StringBuilder;
	
	foreach ($arg in $bodyArgs.Keys) {
		[void]$contents.AppendLine($header);
		[void]$contents.AppendLine("Content-Disposition: form-data; name=`"$arg`"");
		[void]$contents.AppendLine();
		[void]$contents.AppendLine($bodyArgs.Item($arg));
	}
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine("Content-Disposition: form-data; name=`"Filedata`"; filename=`"$file`"");
	[void]$contents.AppendLine("Content-Type: $fileContentType");
	[void]$contents.AppendLine();
	[void]$contents.AppendLine($fileData);
	[void]$contents.AppendLine($footer);
	
	[byte[]]$bytes = $enc.GetBytes($contents);
	$request.ContentLength = $bytes.Length;

	[System.IO.Stream]$reqStream = $request.GetRequestStream();
	$reqStream.Write($bytes, 0, $bytes.Length);
	$reqStream.Flush();
	$reqStream.Close();
}

function Show-BalloonTip {
	[cmdletbinding(SupportsShouldProcess = $true)]
	param(
		[parameter(Mandatory=$true)] [string] $Title,
		[ValidateSet("Info","Warning","Error")] [string] $MessageType = "Info",
		[parameter(Mandatory=$true)] [string] $Message,
		[string] $Duration = 10000,
		[bool] $Dispose = $false
	);
	Add-Type -AssemblyName System.Windows.Forms;
	if ($script:balloon -eq $null) {
		$script:balloon = New-Object System.Windows.Forms.NotifyIcon;
	}
	$balloon.BalloonTipIcon = $MessageType;
	$balloon.BalloonTipText = $Message;
	$balloon.BalloonTipTitle = $Title;
	$balloon.Icon = $Icon;
	$balloon.Visible = $true;
	$balloon.ShowBalloonTip($Duration);
	# if ($Dispose -eq $true) {
		# Start-Sleep -Milliseconds $Duration;
		# $balloon.Dispose();
	# }
}

write-host("You'll get a direct link to your image in clipboard when the script passes.");
write-host("This window will close automatically. Please wait... ");
write-host;

$pattern = "(?i)(\w:[^:]+?\.(?:jpg|jpeg|gif|png|tiff))";
$images = [regex]::matches($files, $pattern);
$filesCount = $images.count;

if ($filesCount -eq 0) {
	write-host('Nothing to upload');
	Show-BalloonTip -Title 'Nothing to upload' -MessageType Error -Message "$matchCount files were submitted. None of them are images." -Duration 6000 -Dispose $true;
	[Environment]::Exit(1);
};
Show-BalloonTip -Title "Uploading..." -MessageType Info -Message "Please wait" -Duration 1000;


# 1st req - startsession

$url = "http://www.imgur.com/upload/start_session/";
$request = Get-RequestWithHeaders -Url $url;
$responseText = Get-ResponseText -request $request;

$sid = Get-RegexMatch -text $responseText -regex '"sid":"(.+?)"';
$cookieSid = "IMGURSESSION=$sid";


# 2nd req - checkcaptcha

if ($filesCount -gt 1) {$createAlbum = 1;} else {$createAlbum = 0;};

$url = "http://imgur.com/upload/checkcaptcha?total_uploads=$filesCount&create_album=$createAlbum&album_title=Optional+Album+Title";

$request = Get-RequestWithHeaders -Url $url -Accept "*/*" -XImgur "1" -Cookie $cookieSid;
$responseText = Get-ResponseText -request $request;

if ($filesCount -gt 1) {$newAlbumId = Get-RegexMatch -text $responseText -regex '"new_album_id":"(.+?)"';};


# 3rd req - upload

$i = 1;
foreach ($imageMatch in $images) {
	$file = $imageMatch.ToString();
	write-host $file;
	
	$url = "http://imgur.com/upload";
	$boundary = [System.Guid]::NewGuid().ToString();
	
	$uploadHeaders = @{
		Url 			= $url;
		Method 			= "POST";
		ContentType 	= "multipart/form-data; boundary=$boundary";
		CacheControl 	= "no-store, no-cache, must-revalidate, post-check=0, pre-check=0";
		Origin 			= "http://imgur.com";
		Cookie 			= $cookieSid;
	};
	$request = Get-RequestWithHeaders @uploadHeaders;
	
	$uploadBodyArgs = New-Object System.Collections.Specialized.OrderedDictionary;
	$uploadBodyArgs.Add("current_upload", $i++);
	$uploadBodyArgs.Add("total_uploads", $filesCount);
	$uploadBodyArgs.Add("terms", "0");
	$uploadBodyArgs.Add("gallery_type", "");
	$uploadBodyArgs.Add("location", "outside");
	$uploadBodyArgs.Add("gallery_submit", "0");
	$uploadBodyArgs.Add("create_album", $createAlbum);
	$uploadBodyArgs.Add("album_title", "Optional Album Title");
	$uploadBodyArgs.Add("sid", $sid);
	if ($filesCount -gt 1) {$uploadBodyArgs.Add("new_album_id", $newAlbumId);};
	
	$fileContentType = Get-ContentType -file $file;
	
	Set-MultipartFormData -request $request -boundary $boundary -bodyArgs $uploadBodyArgs -file $file -fileContentType $fileContentType;

	$responseText = Get-ResponseText -request $request;
	
	write-host("Uploaded.");
	write-host;	
};

$date = Get-Date -UFormat "%d.%m.%y %T";

if ($filesCount -eq 1) {
	$hash = Get-RegexMatch -text $responseText -regex '"hash":"(.+?)"';
	$link = "http://i.imgur.com/$hash$ext";
	$logFile = "log_single.txt";
	$logString = "$link       [$date] $file";
	$title = "Image has been uploaded";
} else {
	$link = "http://imgur.com/a/$newAlbumId";
	$logFile = 'log_albums.txt';
	$logString = "$link       [$date]";
	$title = "$filesCount images have been uploaded";
};

$stream = New-Object System.IO.StreamWriter(New-Object IO.FileStream($logFile, [System.IO.FileMode]::Append));
$stream.WriteLine($logString);
$stream.close();

write-host($link);
write-host;
	
$link | C:\Windows\System32\clip.exe;

Show-BalloonTip -Title $title -MessageType Info -Message "$link - copied to clipboard" -Duration 6000 -Dispose $true;
	
	
powershell