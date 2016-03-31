Param(
	[String]$files
);

$pattern = '(\w:.+?\.\w+)\s|(\w:.+?\.\w+)$';
$filesArray = [regex]::matches($files, $pattern);
$filesCount = $filesArray.count


# 1st req - startsession

$url = 'http://imgur.com/upload/start_session/';
$r = [System.Net.WebRequest]::Create($url);
$resp = $r.GetResponse().GetResponseStream();
$sr = new-object System.IO.StreamReader $resp;
$result = $sr.ReadToEnd();

$found = $result -match '"sid":"(.+?)"';
if ($found) {
    $sid = $matches[1];
};
write-host('sid = {0}' -f $sid);



# 2nd req - checkcaptcha

if ($filesCount -gt 1) {
	$createAlbum = 1;
} else {
	$createAlbum = 0;
};

$url = 'http://imgur.com/upload/checkcaptcha?total_uploads={0}&create_album={1}&album_title=Optional+Album+Title' -f $filesCount, $createAlbum;
$r = [System.Net.WebRequest]::Create($url);

$r.AutomaticDecompression = [System.Net.DecompressionMethods]::Deflate, [System.Net.DecompressionMethods]::GZip; 

$r.KeepAlive="true";
$r.Accept = "*/*";
$r.UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36 OPR/36.0.2130.32";
$r.Referer = "http://imgur.com/";

$r.Headers.Add("Accept-Encoding", "gzip, deflate, lzma, sdch");
$r.Headers.Add("Accept-Language", "ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4");
$r.Headers.Add("X-Requested-With", "XMLHttpRequest");
$r.Headers.Add("X-Imgur", "1");

$resp = $r.GetResponse().GetResponseStream();
$sr = new-object System.IO.StreamReader $resp;
$result = $sr.ReadToEnd();
write-host($result);

if ($filesCount -gt 1) {
	$found = $result -match '"new_album_id":"(.+?)"';
	if ($found) {
		$newAlbumId = $matches[1];
		write-host('new_album_id = {0}' -f $newAlbumId);
	};
};



write-host("You'll get a direct link to your image in clipboard when the script passes.");
write-host("This window will close automatically. Please wait... ");
write-host;



# 3rd req - upload

$contentTypeMap = @{
    ".jpg"  = "image/jpeg";
    ".jpeg" = "image/jpeg";
    ".gif"  = "image/gif";
    ".png"  = "image/png";
    ".tiff" = "image/tiff";
  };

for ($i = 0; $i -lt $filesCount; $i++) {
	$file = $filesArray[$i].ToString().Trim();
	
	write-host $file
	
	$dotPosition = $file.LastIndexOf('.');
	$slashPosition = $file.LastIndexOf('\');
	
	if ($slashPosition -eq -1) {
		$fileName = $file.Substring(0, $dotPosition);
	} else {
		$fileName = $file.Substring($slashPosition + 1, $dotPosition - $slashPosition - 1);
	};
	$ext = $file.Substring($dotPosition).ToLower();

	if ($contentTypeMap[$ext]) {
		$contentType = $contentTypeMap[$ext]; 
	} else {
		write-host('Incorrect extension type');
		# [Environment]::Exit(1);				# TODO
	};
	
	
	$url = 'http://imgur.com/upload';
	$r = [System.Net.WebRequest]::Create($url);

	$r.AutomaticDecompression = [System.Net.DecompressionMethods]::Deflate, [System.Net.DecompressionMethods]::GZip; 
	
	$boundary = [System.Guid]::NewGuid().ToString();
	
	$r.ContentType = "multipart/form-data; boundary={0}; charset=UTF-8" -f $boundary;
	$r.Method = "POST";
	$r.UserAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36 OPR/36.0.2130.32";
	$r.Accept = "application/json, text/javascript, */*; q=0.01";
	$r.Referer = "http://imgur.com/";
	$r.KeepAlive="true";
	
	$r.Headers.Add("Accept-Encoding", "gzip, deflate, lzma");
	$r.Headers.Add("Accept-Language", "ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4");
	$r.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, post-check=0, pre-check=0");
	$r.Headers.Add("Origin", "http://imgur.com");
	$r.Headers.Add("X-Requested-With", "XMLHttpRequest");
	
	$bytes = [System.IO.File]::ReadAllBytes($file);
	$enc = [System.Text.Encoding]::GetEncoding(0);
	$filedata = $enc.GetString($bytes);	

	$header = "--{0}" -f $boundary;
	$footer = "--{0}--" -f $boundary;
	[System.Text.StringBuilder]$contents = New-Object System.Text.StringBuilder;
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="current_upload"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine($i + 1);
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="total_uploads"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine($filesCount);
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="terms"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine('0');
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="gallery_type"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine();
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="location"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine('outside');
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="gallery_submit"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine('0');
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="create_album"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine($createAlbum);
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="album_title"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine('Optional Album Title');
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="sid"');
	[void]$contents.AppendLine();
	[void]$contents.AppendLine($sid);
	
	if ($filesCount -gt 1) {
		[void]$contents.AppendLine($header);
		[void]$contents.AppendLine('Content-Disposition: form-data; name="new_album_id"');
		[void]$contents.AppendLine();
		[void]$contents.AppendLine($newAlbumId);
	};
	
	[void]$contents.AppendLine($header);
	[void]$contents.AppendLine('Content-Disposition: form-data; name="Filedata"; filename="{0}"' -f $fileName);
	[void]$contents.AppendLine('Content-Type: {0}' -f $contentType);
	[void]$contents.AppendLine();
	[void]$contents.AppendLine($filedata);
	
	[void]$contents.AppendLine($footer);


	$enc = [System.Text.Encoding]::GetEncoding(0);
	[byte[]]$bytes = $enc.GetBytes($contents.ToString());
	$r.ContentLength = $bytes.Length;

	[System.IO.Stream]$reqStream = $r.GetRequestStream();
	$reqStream.Write($bytes, 0, $bytes.Length);
	$reqStream.Flush();
	$reqStream.Close();
	
	$resp = $r.GetResponse().GetResponseStream();
	
	$sr = new-object System.IO.StreamReader $resp;
	$result = $sr.ReadToEnd();
	write-host($result);
		
};

if ($filesCount -eq 1) {

	$found = $result -match '"hash":"(.+?)"'
	if ($found) {
		$hash = $matches[1];
	};
	write-host('hash = {0}' -f $hash);

	$link = 'http://i.imgur.com/{0}{1}' -f $hash, $ext;
	
} else {

	$link = 'http://imgur.com/a/{0}' -f $newAlbumId;
	
};

write-host;
write-host($link);
write-host;
	
$link | C:\Windows\System32\clip.exe;


<#








$date = Get-Date -UFormat "%d.%m.%y %T";
$logString = "{0}       [{1}] {2}" -f $link, $date, $file;

$stream = New-Object System.IO.StreamWriter(New-Object IO.FileStream("log.txt", [System.IO.FileMode]::Append));
$stream.WriteLine($logString);
$stream.close();

$link | C:\Windows\System32\clip.exe;

#>
powershell