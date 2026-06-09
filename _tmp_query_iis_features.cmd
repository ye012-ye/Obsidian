@echo off
set OUT=C:\Users\35502\AppData\Local\Temp\u8_iis_feature_dump.txt
> "%OUT%" echo ==== IIS-WebServerRole ====
dism /online /Get-FeatureInfo /FeatureName:IIS-WebServerRole >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-Metabase ====
dism /online /Get-FeatureInfo /FeatureName:IIS-Metabase >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-IIS6ManagementCompatibility ====
dism /online /Get-FeatureInfo /FeatureName:IIS-IIS6ManagementCompatibility >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-WMICompatibility ====
dism /online /Get-FeatureInfo /FeatureName:IIS-WMICompatibility >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-ManagementScriptingTools ====
dism /online /Get-FeatureInfo /FeatureName:IIS-ManagementScriptingTools >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== IIS-ASP ====
dism /online /Get-FeatureInfo /FeatureName:IIS-ASP >> "%OUT%"
