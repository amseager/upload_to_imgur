Param(
	[String] $batArgs
);
$CurrentDirectory = [environment]::CurrentDirectory;
$Icon = "$CurrentDirectory\icon.ico";

function Get-ResponseText {
	param(
		[System.Net.WebRequest] $request
	);
	$response = $request.GetResponse().GetResponseStream();
	$sr = new-object System.IO.StreamReader $response;
	$responseText = $sr.ReadToEnd();
	return $responseText;
}

function Get-RegexMatch {
	param(
		 [string] $text,
		 [string] $regex
	);
	$found = $text -match $regex;
	if ($found) {$match = $matches[1];};
	return $match;
}

function Get-ImageContentType {
	param(
		[string] $image
	)
	$contentTypeMap = @{
		".jpg"  = "image/jpeg";
		".jpeg" = "image/jpeg";
		".gif"  = "image/gif";
		".png"  = "image/png";
		".tiff" = "image/tiff";
		".pdf"  = "application/pdf";
	};
	$ext = $image.Substring($image.LastIndexOf(".")).ToLower();
	$imageContentType = $contentTypeMap[$ext];
	return $imageContentType;
}

function Get-RequestWithHeaders {
	param(
		[string] $Url,
		[ValidateSet('GET','POST')] [string] $Method = 'GET',
		[bool] $KeepAlive = $true,
		[string] $AutomaticDecompression = "Deflate, GZip",
		[string] $Referer = "http://imgur.com/",
		[string] $UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36 OPR/36.0.2130.32",
		[string] $Accept = "application/json, text/javascript, */*; q=0.01",
		[string] $AcceptEncoding = "lzma, sdch",
		[string] $AcceptLanguage = "ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4",
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
	
	if ($ContentType -ne '') 	{$request.ContentType = $ContentType};
	if ($CacheControl -ne '') 	{$request.Headers.Add("Cache-Control", $CacheControl)};
	if ($Cookie -ne '') 		{$request.Headers.Add("Cookie", $Cookie)};
	if ($Origin -ne '') 		{$request.Headers.Add("Origin", $Origin)};
	if ($XImgur -ne '') 		{$request.Headers.Add("X-Imgur", $XImgur)};
	
	return $request;
}

function Set-MultipartBody {
	param(
		[System.Net.WebRequest] $request,
		[string] $boundary,
		[System.Collections.Specialized.OrderedDictionary]$bodyArgs,
		[string] $image,
		[string] $imageContentType
	);
	$enc = [System.Text.Encoding]::GetEncoding(0);
	$imageDataBytes = [System.IO.File]::ReadAllBytes($image);
	$imageData = $enc.GetString($imageDataBytes);	
	
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
	[void]$contents.AppendLine("Content-Disposition: form-data; name=`"Filedata`"; filename=`"$image`"");
	[void]$contents.AppendLine("Content-Type: $imageContentType");
	[void]$contents.AppendLine();
	[void]$contents.AppendLine($imageData);
	[void]$contents.AppendLine($footer);
	
	[byte[]]$bytes = $enc.GetBytes($contents);
	$request.ContentLength = $bytes.Length;

	[System.IO.Stream]$reqStream = $request.GetRequestStream();
	$reqStream.Write($bytes, 0, $bytes.Length);
	$reqStream.Flush();
	$reqStream.Close();
}

function Set-UrlencodedBody {
	param(
		[System.Net.WebRequest] $request,
		[string] $urlencodedBody
	);
	$enc = [System.Text.Encoding]::GetEncoding(0);
	[byte[]]$bytes = $enc.GetBytes($body);
	$request.ContentLength = $bytes.Length;

	[System.IO.Stream]$reqStream = $request.GetRequestStream();
	$reqStream.Write($bytes, 0, $bytes.Length);
	$reqStream.Flush();
	$reqStream.Close();
}

function Show-BalloonTip {
	[cmdletbinding(SupportsShouldProcess = $true)]
	param(
		[string] $Title,
		[ValidateSet("Info","Warning","Error")] [string] $MessageType = "Info",
		[string] $Message,
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
	if ($Dispose -eq $true) {
		Start-Sleep -Milliseconds $Duration;
		$balloon.Dispose();
	}
}


$allFiles = @();
$allPattern = "(?i)(\w:[^:]+?)(?=\s\w:|$)";
$allMatches = [regex]::matches($batArgs, $allPattern);

foreach ($match in $allMatches) {
	$path = $match.ToString();
	$isDirectory = (Get-Item $path) -is [System.IO.DirectoryInfo];
	if ($isDirectory) {
		$filesInDirectory = Get-ChildItem $path -recurse | Where-Object {$_.PSIsContainer -eq $false} | % { $_.FullName }
		$allFiles += $filesInDirectory;
	} else {
		$allFiles += $path;
	}
}
$imagePattern = "(?i)(\w:[^:]+?\.(?:jpg|jpeg|gif|png|tiff|pdf))";
$images = [regex]::matches($allFiles, $imagePattern);
$imagesCount = $images.count;

if ($imagesCount -eq 0) {
	write-host("Nothing to upload");
	Show-BalloonTip -Title "Nothing to upload" -MessageType Error -Message "No images were submitted" -Duration 6000 -Dispose $true;
	[Environment]::Exit(1);
};
write-host("You'll get a direct link to your image in clipboard when the script passes.");
write-host("This window will close automatically. Please wait... ");
write-host;
if ($imagesCount -eq 1) {$uploadingTitle = "Uploading image..."} else {$uploadingTitle = "Uploading $imagesCount images..."};
Show-BalloonTip -Title $uploadingTitle -MessageType Info -Message "Please wait" -Duration 1000;


# 1st req - startsession

$url = "http://www.imgur.com/upload/start_session/";
$request = Get-RequestWithHeaders -Url $url -XRequestedWith "XMLHttpRequest";
$responseText = Get-ResponseText -request $request;

$sid = Get-RegexMatch -text $responseText -regex '"sid":"(.+?)"';
$cookieSid = "IMGURSESSION=$sid";


# 2nd req - checkcaptcha

if ($imagesCount -gt 1) {$createAlbum = 1;} else {$createAlbum = 0;};

$url = "http://imgur.com/upload/checkcaptcha?total_uploads=$imagesCount&create_album=$createAlbum&album_title=Optional+Album+Title";
$request = Get-RequestWithHeaders -Url $url -Accept "*/*" -XImgur "1" -XRequestedWith "XMLHttpRequest" -Cookie $cookieSid;
$responseText = Get-ResponseText -request $request;

if ($imagesCount -gt 1) {$newAlbumId = Get-RegexMatch -text $responseText -regex '"new_album_id":"(.+?)"';};


# 3rd req - upload

$i = 1;
foreach ($image in $images) {
	write-host $image;
	
	$url = "http://imgur.com/upload";
	$boundary = [System.Guid]::NewGuid().ToString();
	
	$uploadHeaders = @{
		Url 			= $url;
		Method 			= "POST";
		ContentType 	= "multipart/form-data; boundary=$boundary";
		CacheControl 	= "no-store, no-cache, must-revalidate, post-check=0, pre-check=0";
		Origin 			= "http://imgur.com";
		Cookie 			= $cookieSid;
		XRequestedWith  = "XMLHttpRequest";
	};
	$uploadBodyArgs = New-Object System.Collections.Specialized.OrderedDictionary;
	$uploadBodyArgs.Add("current_upload", $i++);
	$uploadBodyArgs.Add("total_uploads", $imagesCount);
	$uploadBodyArgs.Add("terms", "0");
	$uploadBodyArgs.Add("gallery_type", "");
	$uploadBodyArgs.Add("location", "outside");
	$uploadBodyArgs.Add("gallery_submit", "0");
	$uploadBodyArgs.Add("create_album", $createAlbum);
	$uploadBodyArgs.Add("album_title", "Optional Album Title");
	$uploadBodyArgs.Add("sid", $sid);
	if ($imagesCount -gt 1) {$uploadBodyArgs.Add("new_album_id", $newAlbumId);};
	
	$imageContentType = Get-ImageContentType -image $image;
	
	$isUploadSuccessful = $false;
	while ($isUploadSuccessful -eq $false) {
		try {
			$request = Get-RequestWithHeaders @uploadHeaders;
			Set-MultipartBody -request $request -boundary $boundary -bodyArgs $uploadBodyArgs -image $image -imageContentType $imageContentType;
			$response = $request.GetResponse();
			$isUploadSuccessful = $true;
		} catch [System.Net.WebException] {
			$statusCode = [int]$_.Exception.Response.StatusCode
			if ($statusCode -eq 500) {
				Start-Sleep -s 10;
			} else {
				Show-BalloonTip -Title "Error code $statusCode" -MessageType Info -Message "Please try again later" -Duration 6000 -Dispose $true;
				[Environment]::Exit(1);
			}
		}
	}
	write-host("Uploaded.");
	write-host;	
};

$date = Get-Date -UFormat "%d.%m.%y %T";

if ($imagesCount -eq 1) {
	$responseText = Get-ResponseText -request $request;
	$hash = Get-RegexMatch -text $responseText -regex '"hash":"(.+?)"';
	$link = "http://i.imgur.com/$hash.jpg";
	$logFile = "../logs/log_single.txt";
	$logString = "$link       [$date] $image";
	$title = "Image has been uploaded";
} else {
	$link = "http://imgur.com/a/$newAlbumId";
	$logFile = '../logs/log_albums.txt';
	$logString = "$link       [$date]";
	$title = "$imagesCount images have been uploaded";
};

$stream = New-Object System.IO.StreamWriter(New-Object IO.FileStream($logFile, [System.IO.FileMode]::Append));
$stream.WriteLine($logString);
$stream.close();

write-host($link);
write-host;
	
$link | C:\Windows\System32\clip.exe;

Show-BalloonTip -Title $title -MessageType Info -Message "$link - copied to clipboard" -Duration 6000 -Dispose $true;
	
	
#powershell