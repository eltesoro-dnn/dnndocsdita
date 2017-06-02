@echo off
if _%1_ EQU __  goto :usage
goto %1

:swagger
if _%2_ EQU _f_  call %0 runme "" json\%1.json bptext-api w:\_content\api
if _%2_ NEQ _f_  call %0 runme qa-sc.dnnapi.com/swagger/docs/v1 json\%1.json bptext-api w:\_content\api
goto :eof


:runme
if _%4_ EQU __  goto :error
cd /d %~dp0
if not exist %~dp0out\*  md %~dp0out > nul
del %~dp0out\* /q
powershell -file mkapi.ps1 %2 %3 %4 %~dp0out %5
call windiff %5\* %~dp0out\*

echo.
echo *** Would you like to copy modified files from %~dp0out to %5? (Note: Only existing files are updated.) [y/n] ***
set /p _ans=[y/n]
if _%_ans%_ -ne y  goto :review
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
echo USAGE: %0 folder
echo EXAMPLE: %0 roles
goto :eof
