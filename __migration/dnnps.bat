@echo off

set bldsite=E911-133-00
if _%2_ NEQ __  set bldsite=%2


for /f "usebackq" %%v in ( `findstr /i /m /c:%1 json\jobs*.json` ) do (
    echo *** powershell -file dnnps.ps1 json\settings-doccenter-%bldsite%.json %%v %1
    powershell -file dnnps.ps1 json\settings-doccenter-%bldsite%.json %%v %1
    goto :eof
)
:. for %%v in ( contenttype choice conceptual image person product reference requisite solution step substep section subsection task troubleshooting ) do ( echo _%1_ | findstr /i /c:%%v >nul && (
:.     powershell -file dnnps.ps1 json\settings-doccenter-%bldsite%.json json\jobs-%%vs.json %1
:.     goto :eof
:. ) )



:. powershell -file dnnps.ps1 json\settings-doccenter-%bldsite%.json json\jobs.json %1
goto :eof
