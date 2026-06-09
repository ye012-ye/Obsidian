@echo off
set OUT=C:\Users\35502\AppData\Local\Temp\u8_enable_aspnet_iis.log
> "%OUT%" echo ==== IIS-NetFxExtensibility ====
dism /online /Enable-Feature /FeatureName:IIS-NetFxExtensibility /All /NoRestart >> "%OUT%" 2>&1
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-NetFxExtensibility45 ====
dism /online /Enable-Feature /FeatureName:IIS-NetFxExtensibility45 /All /NoRestart >> "%OUT%" 2>&1
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-ASPNET ====
dism /online /Enable-Feature /FeatureName:IIS-ASPNET /All /NoRestart >> "%OUT%" 2>&1
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-ASPNET45 ====
dism /online /Enable-Feature /FeatureName:IIS-ASPNET45 /All /NoRestart >> "%OUT%" 2>&1
