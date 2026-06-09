@echo off
dism /online /Get-Features /Format:Table | findstr /I "WAS WCF NetFxEnvironment" > "C:\Users\35502\AppData\Local\Temp\u8_was_wcf_dism.txt"
