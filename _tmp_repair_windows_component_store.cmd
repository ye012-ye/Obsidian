@echo off
set OUT=C:\Users\35502\AppData\Local\Temp\u8_component_repair.log
> "%OUT%" echo ==== DISM RestoreHealth ====
dism /online /cleanup-image /restorehealth >> "%OUT%" 2>&1
>> "%OUT%" echo.
>> "%OUT%" echo ==== SFC Scannow ====
sfc /scannow >> "%OUT%" 2>&1
