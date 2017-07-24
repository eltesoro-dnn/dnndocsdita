@echo off

set bldsite=E911-133-00
if _%2_ NEQ __  set bldsite=%2


echo *** powershell -file dnnps2.ps1 json\settings-doccenter-%bldsite%.json %1 json\jobs*.json
powershell -file dnnps2.ps1 json\settings-doccenter-%bldsite%.json %1 json\jobs*.json
goto :eof
