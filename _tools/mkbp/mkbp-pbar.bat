@echo off
if _%1_ EQU __ goto :usage

:. powershell -file convertxlsx2csv.ps1 W:\_tools\mkbp

:. Do not refresh these files inside the .ps1 files because we want them to be cumulative if wildcards are used in %1.
powershell -file refresh-files.ps1 mkbp-pbar-steps.out
powershell -file refresh-files.ps1 mkbp-css.out

for %%v in ( %* ) do  for /f "usebackq" %%w in ( `dir %%v /b` ) do (
    powershell -file mkbp-pbar-steps.ps1 %%w mkbp-pbar-steps.out
    powershell -file mkbp-css.ps1 %%w mkbp-css.out
)

npp mkbp-pbar-steps.out mkbp-css.out

goto :eof

:usage
echo USAGE: %0 pbar-xxxyyy.csv
echo EXAMPLE: %0 *E90*csv