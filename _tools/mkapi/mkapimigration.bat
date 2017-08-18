@echo off

if _%swaggerpath%_ EQU __  goto setswagger
powershell -file mkapimigration.ps1 %swaggerpath% json\swagger.json json\webapi-templates.json out

dir out\*webapi*.out

:. Compare and copy.
echo Comparing h:\json\*webapi*.json and out\*webapi*.out. . . .
for /f "usebackq" %%v in ( `dir out\*webapi*.out /b` ) do (
    windiff h:\json\%%~nv.json out\%%~nv.out
    rem powershell -Command "&{ Compare-Object $( Get-Content h:\json\%%~nv.json ) $( Get-Content out\%%~nv.out ) -includeequal }"
)
set /p _ans_=Copy out\*webapi*.out to h:\json\*webapi*.json? [n/y]
if _%_ans_%_ EQU _y_  xcopy out\*webapi*.out h:\json\*webapi*.json /v /y

goto :eof

:setswagger
echo ERROR: You must set the swaggerpath evar before running this script.
goto : eof
