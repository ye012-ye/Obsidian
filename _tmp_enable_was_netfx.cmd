@echo off
set OUT=C:\Users\35502\AppData\Local\Temp\u8_enable_was_netfx.log
> "%OUT%" echo ==== WAS-NetFxEnvironment ====
dism /online /Enable-Feature /FeatureName:WAS-NetFxEnvironment /All /NoRestart >> "%OUT%" 2>&1
>> "%OUT%" echo.
>> "%OUT%" echo ==== WAS-ProcessModel ====
dism /online /Enable-Feature /FeatureName:WAS-ProcessModel /All /NoRestart >> "%OUT%" 2>&1
>> "%OUT%" echo.
>> "%OUT%" echo ==== WAS-ConfigurationAPI ====
dism /online /Enable-Feature /FeatureName:WAS-ConfigurationAPI /All /NoRestart >> "%OUT%" 2>&1
