$src = Join-Path $env:SystemRoot 'System32\wbem\iiswmi.mof'
$dst = 'C:\Users\35502\AppData\Local\Temp\iiswmi_32compat.mof'

$content = Get-Content $src
$content = $content | Where-Object { $_ -notmatch '^\s*#pragma classflags\(64\)\s*$' }
Set-Content -Path $dst -Value $content -Encoding ASCII

Write-Output $dst
