@echo off
powershell -NoProfile -Command "Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like 'WAS*' -or $_.FeatureName -like 'WCF*' } | Sort-Object FeatureName | Select-Object FeatureName,State | Out-File -Encoding utf8 C:\Users\35502\AppData\Local\Temp\u8_was_wcf_features.txt"
