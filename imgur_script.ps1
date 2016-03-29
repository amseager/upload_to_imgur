Param(
	[String]$file
);

$dotPosition = $file.LastIndexOf('.');
$slashPosition = $file.LastIndexOf('\');

$ext = $file.Substring($dotPosition).ToLower();
if ($slashPosition -eq -1) {
	$fileName = $file.Substring(0, $dotPosition);
} else {
	$fileName = $file.Substring($slashPosition + 1, $dotPosition - $slashPosition - 1);
};

$contentTypeMap = @{
    ".jpg"  = "image/jpeg";
    ".jpeg" = "image/jpeg";
    ".gif"  = "image/gif";
    ".png"  = "image/png";
    ".tiff" = "image/tiff";
  }
if ($contentTypeMap[$ext]) {
	$contentType = $contentTypeMap[$ext]; 
} else {
	write-host('Incorrect extension type');
	[Environment]::Exit(1);
};

$r = [System.Net.WebRequest]::Create("http://imgur.com/upload/start_session/");
$resp = $r.GetResponse().GetResponseStream();
$sr = new-object System.IO.StreamReader $resp;
$result = $sr.ReadToEnd();

$found = $result -match '"sid":"(.+?)"';
if ($found) {
    $sid = $matches[1];
};
write-host('sid = {0}' -f $sid);

$r = [System.Net.WebRequest]::Create("http://imgur.com/upload/checkcaptcha?total_uploads=1&create_album=0&album_title=Optional+Album+Title");
$resp = $r.GetResponse().GetResponseStream();
$sr = new-object System.IO.StreamReader $resp;
$result = $sr.ReadToEnd();
write-host($result);

$url='http://imgur.com/upload?current_upload=1&total_uploads=1&terms=0&gallery_type=&location=outside&gallery_submit=0&create_album=0&album_title=Optiona%20Album%20Title&sid={0}' -f $sid;

$bytes = [System.IO.File]::ReadAllBytes($file);
$enc = [System.Text.Encoding]::GetEncoding(0);
$filedata = $enc.GetString($bytes);	

$boundary = [System.Guid]::NewGuid().ToString();
$header = "--{0}" -f $boundary;
$footer = "--{0}--" -f $boundary;

[System.Text.StringBuilder]$contents = New-Object System.Text.StringBuilder;
[void]$contents.AppendLine($header);
[void]$contents.AppendLine('Content-Disposition: form-data; name="Filedata"; filename="{0}"' -f $fileName);
[void]$contents.AppendLine('Content-Type: {0}' -f $contentType);
[void]$contents.AppendLine('Content-Transfer-Encoding: binary');
[void]$contents.AppendLine();
[void]$contents.AppendLine($filedata);
[void]$contents.AppendLine($footer);

$postContentType = "multipart/form-data; boundary={0}; charset=UTF-8" -f $boundary;

$r = [System.Net.WebRequest]::Create($url);

$r.ContentType = $postContentType;
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


$enc = [System.Text.Encoding]::GetEncoding(0);
[byte[]]$bytes = $enc.GetBytes($contents.ToString());
$r.ContentLength = $bytes.Length;

[System.IO.Stream]$reqStream = $r.GetRequestStream();
$reqStream.Write($bytes, 0, $bytes.Length);
$reqStream.Flush();
$reqStream.Close();

$resp = $r.GetResponse().GetResponseStream();

$gzipStream = New-Object System.IO.Compression.GzipStream $resp, ([IO.Compression.CompressionMode]::Decompress);
$output = New-Object System.IO.MemoryStream;
$buffer = New-Object byte[](512);
while ($true) {
	$read = $gzipStream.Read($buffer, 0, 512);
	if ($read -le 0) {
		break;
	};
	$output.Write($buffer, 0, $read);
};
$enc = [System.Text.Encoding]::GetEncoding(0);
$result = $enc.GetString($output.ToArray());	
write-host($result);

$found = $result -match '"hash":"(.+?)"'
if ($found) {
    $hash = $matches[1];
};
write-host('hash = {0}' -f $hash);

$link = 'http://i.imgur.com/{0}{1}' -f $hash, $ext;

write-host;
write-host($link);
write-host;

$link | C:\Windows\System32\clip.exe;
