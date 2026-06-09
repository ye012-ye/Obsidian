param(
    [string]$Path,
    [string]$Pattern = 'IIS|InetStp|W3SVC|IISADMIN|MetaBase|adsutil|winmgmts|MicrosoftIISv2|IIsWebService|GetObject'
)

$bytes = [System.IO.File]::ReadAllBytes($Path)
$sb = New-Object System.Text.StringBuilder
$matches = New-Object System.Collections.Generic.List[string]

for ($i = 0; $i -lt $bytes.Length - 1; $i += 2) {
    $code = [BitConverter]::ToUInt16($bytes, $i)
    if (($code -ge 32 -and $code -le 126) -or ($code -ge 0x4e00 -and $code -le 0x9fff)) {
        [void]$sb.Append([char]$code)
    } else {
        if ($sb.Length -ge 4) {
            $s = $sb.ToString()
            if ($s -match $Pattern) {
                $matches.Add($s)
            }
        }
        $sb.Clear() | Out-Null
    }
}

if ($sb.Length -ge 4) {
    $s = $sb.ToString()
    if ($s -match $Pattern) {
        $matches.Add($s)
    }
}

$matches | Sort-Object -Unique
