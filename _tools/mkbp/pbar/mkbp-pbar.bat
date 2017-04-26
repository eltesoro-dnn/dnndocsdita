@echo off
if _%1_ EQU __ goto :usage

:. powershell -file convertxlsx2csv.ps1 W:\_tools\mkbp
set _ps1lib=W:\_tools\lib

:. Do not refresh these files inside the .ps1 files because we want them to be cumulative if wildcards are used in %1.
if exist mkbp-pbar-steps.out   del mkbp-pbar-steps.out  > nul
if exist mkbp-css.out          del mkbp-css.out         > nul

for %%v in ( %* ) do  for /f "usebackq" %%w in ( `dir %%v /b` ) do (
    powershell -file mkbp-pbar-steps.ps1 %%w mkbp-pbar-steps.out
    powershell -file mkbp-css.ps1 %%w mkbp-css.out
)

if exist mkbp-pbar-steps.out  (
    windiff w:\_content\common\bptext-pbar.dita mkbp-pbar-steps.out
    npp     w:\_content\common\bptext-pbar.dita mkbp-pbar-steps.out
)

if exist mkbp-css.out  (
    windiff w:\_themes\dnn\dnndocsltr.css mkbp-css.out
    npp     w:\_themes\dnn\dnndocs*.css   mkbp-css.out
)


goto :eof

:usage
echo USAGE: %0 pbar-xxxyyy.csv
echo EXAMPLE: %0 pbar-E91*csv