@echo off
powershell -NoProfile -Command "Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like 'IIS*' -or $_.FeatureName -like 'NetFx4Extended-ASPNET45' } | Sort-Object FeatureName | Select-Object FeatureName,State | Out-File -Encoding utf8 C:\Users\35502\AppData\Local\Temp\u8_all_iis_features.txt"
