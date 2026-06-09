@echo off
set OUT=C:\Users\35502\AppData\Local\Temp\u8_was_feature_dump.txt
> "%OUT%" echo ==== WAS-NetFxEnvironment ====
dism /online /Get-FeatureInfo /FeatureName:WAS-NetFxEnvironment >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== WAS-ConfigurationAPI ====
dism /online /Get-FeatureInfo /FeatureName:WAS-ConfigurationAPI >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== WAS-ProcessModel ====
dism /online /Get-FeatureInfo /FeatureName:WAS-ProcessModel >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== WCF-HTTP-Activation45 ====
dism /online /Get-FeatureInfo /FeatureName:WCF-HTTP-Activation45 >> "%OUT%"
>> "%OUT%" echo.
>> "%OUT%" echo ==== WCF-NonHTTP-Activation ====
dism /online /Get-FeatureInfo /FeatureName:WCF-NonHTTP-Activation >> "%OUT%"
