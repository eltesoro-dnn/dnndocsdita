@echo off
if _%1_ EQU __ goto :usage

echo. > mkbp-pbar-steps.out
echo. > mkbp-css.out
for %%v in ( %* ) do  for /f "usebackq" %%w in ( `dir %%v /b` ) do (
    powershell -file mkbp-pbar-steps.ps1 %%w >> mkbp-pbar-steps.out
    powershell -file mkbp-css.ps1 %%w >> mkbp-css.out
)
npp mkbp-pbar-steps.out mkbp-css.out

goto :eof

:usage
echo USAGE: %0 pbar-xxxyyy.csv
