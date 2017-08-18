@echo off
if _%bldsite%_ EQU __  goto errbldsite

if _%1_ EQU _ct_  goto :ctypes-%2
if _%1_ EQU _ci_  goto :citems
goto :Usage

:ctypes-add
for /d %%v in ( WebApiField WebApiDto WebApiParam WebApiSection WebApiMethod ) do (
    call dnnps.bat add-contenttype-%%v
    call dnnps.bat listall-contenttypes
)
goto :eof

:ctypes-listall
call dnnps.bat listall-contenttypes
goto :eof


:citems
set act=%2
set typelist=webapifields webapidtos webapiparams webapisections webapimethods
if _%3_ NEQ __ set typelist=%3 %4 %5 %6 %7 %8 %9
for /d %%v in ( %typelist% ) do (
    call dnnps %act%-%%v
    if _%act%_ NEQ _listall_  call dnnps.bat listall-%%v
)
goto :eof


:errbldsite
echo ERROR: You must set the evar 'bldsite'.
goto :eof


:Usage
echo USAGE:
echo     %0 ct add
echo     %0 ct listall
echo     %0 ci add
echo     %0 ci listall
echo     %0 ci deleteall
goto :eof
