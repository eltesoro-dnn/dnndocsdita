@echo off
if _%1_ EQU __  goto :usage

cd /d %~p0
if not exist out\*  md out > nul
goto %1


:roles
powershell -file mkbp-generic-steps.ps1 rolessteps.in .\out-%1\bptext-rolessteps.dita
powershell -file mkbp-generic-files.ps1 rolesfiles.in bptext-rolessteps prolog.txt presteps.txt .\out-%1
:. powershell -file mkbp-compare-copy.ps1
start windiff W:\_content\common\roles\* out-%1\*
:. for /f "usebackq" %%v in (`dir out-%1\*.dita /b`) do fc W:\_content\common\roles\%%v out-%1\%%v
:. for /f "usebackq" %%v in (`dir out-%1\*.dita /b`) do if _%%v_ NEQ _bptext-rolessteps.dita_ xcopy out-%1\%%v W:\_content\common\roles /v /y
:. for /f "usebackq" %v in (`dir out-%1\*.dita /b`) do if _%v_ NEQ _bptext-rolessteps.dita_ xcopy out-%1\%v W:\_content\common\roles /v /y
npp W:\_content\common\roles\bp*
npp out-%1\bp*
goto :eof


:usage
echo.
echo USAGE: %0 folder
echo EXAMPLE: %0 roles
goto :eof
