@echo off
if _%1_ EQU __  goto :usage
goto %1

:swagger
if _%2_ EQU _f_  call %0 runme "" json\%1.json bptext-api w:\_content\api
if _%swaggerpath%_ EQU __  goto setswagger
if _%2_ NEQ _f_  call %0 runme %swaggerpath% json\%1.json bptext-api w:\_content\api
goto :eof
:setswagger
echo ERROR: You must set the swaggerpath evar before running this script.
goto : eof


:runme
if _%4_ EQU __  goto :error
cd /d %~dp0
if not exist %~dp0out\*  md %~dp0out > nul
del %~dp0out\* /q
powershell -file mkapi.ps1 %2 %3 %4 %~dp0out %5
call windiff %5\* %~dp0out\*

echo.
echo *** Would you like to copy modified files from %~dp0out to %5? (Note: Only existing files are updated.) ***
set /p _ans=[y/n]
if _%_ans%_ NEQ _y_  goto :review
cd /d %5
for /f "usebackq" %%v in ( `dir *.* /b` ) do  if exist %~dp0out\%%v  xcopy %~dp0out\%%v %5 /v
:review
start %5
start %~dp0out
npp %5\bp* %~dp0out\bp*
goto :eof


:error
echo.
echo ERROR: Insufficient parameters in internal call.
goto :eof

:usage
echo.
echo USAGE: %0 folder [f]
echo    where f indicates that the local copy of the swagger.json file should be used, instead of retrieving it again from \%swaggerpath\%.
echo EXAMPLES:
echo    %0 swagger
echo    %0 swagger f
goto :eof
