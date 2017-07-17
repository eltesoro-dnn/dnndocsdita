@echo off

set mkbpdir=W:\_tools\mkbp
del /q /f out\jobs-*.out >nul

echo *** Building out\jobs-images-pbar*.out . . . .
for /f "usebackq" %%v in ( `dir %mkbpdir%\pbar\pbar-E91*.csv /b` ) do powershell -file mkpermutations.ps1 %mkbpdir%\pbar\%%v out\jobs-images-%%~nv.out
for /f "usebackq" %%v in ( `dir out\jobs-images-%%~nv.out /b` ) do type out\%%v >> out\jobs-images-pbar.out

echo *** Building out\jobs-steps-pbar*.out . . . .
for /f "usebackq" %%v in ( `dir %mkbpdir%\pbar\pbar-E91*.csv /b` ) do powershell -file mkpermutations.ps1 %mkbpdir%\pbar\%%v out\jobs-steps-%%~nv.out
for /f "usebackq" %%v in ( `dir out\jobs-steps-%%~nv.out /b` ) do type out\%%v >> out\jobs-steps-pbar.out

echo *** Building out\jobs-images-pbtabs.out . . . .
powershell -file mkpermutations.ps1 %mkbpdir%\pbtabs\pbtabs-E91.csv out\jobs-images-pbtabs.out

echo *** Building out\jobs-steps-pbtabs.out . . . .
powershell -file mkpermutations.ps1 %mkbpdir%\pbtabs\pbtabs-E91.csv out\jobs-steps-pbtabs.out

call npp out\jobs-*-pbar.out
call npp out\jobs-*-pbtabs.out