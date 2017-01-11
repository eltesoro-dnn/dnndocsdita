@echo off
if _%1_ EQU __  goto :usage
goto %1


:roles
call %0 runme json\rolesfiles.json bptext-rolessteps W:\_content\common\roles
goto :eof





:runme
if _%4_ EQU __  goto :error
cd /d %~p0
if not exist %~dp0out\*  md %~dp0out > nul
powershell -file mkbp-generic-files-json.ps1 %2 %3 prolog.txt presteps.txt %~dp0out
start windiff %4\* %~dp0out\*
npp %4\bp*
npp %~dp0out\bp*
goto :eof

:. powershell -file mkbp-compare-copy.ps1
:. for /f "usebackq" %%v in (`dir out-%1\*.dita /b`) do fc W:\_content\common\roles\%%v out-%1\%%v
:. for /f "usebackq" %%v in (`dir out-%1\*.dita /b`) do if _%%v_ NEQ _bptext-rolessteps.dita_ xcopy out-%1\%%v W:\_content\common\roles /v /y
:. for /f "usebackq" %v in (`dir out-%1\*.dita /b`) do if _%v_ NEQ _bptext-rolessteps.dita_ xcopy out-%1\%v W:\_content\common\roles /v /y



:error
echo.
echo ERROR: Insufficient parameters in internal call.
goto :eof

:usage
echo.
echo USAGE: %0 folder
echo EXAMPLE: %0 roles
goto :eof
