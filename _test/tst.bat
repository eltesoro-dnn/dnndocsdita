@echo off
cls
if "%OS%"=="Windows_NT" @setlocal
if "%OS%"=="WINNT" @setlocal

:. ----- Modify the environment settings below as needed. -----

:. Choose one output format or specify it in as the first parameter to this batch file.
:. Currently available: html5, xhtml, word2dita.
:. Future options: common-html, docbook, eclipsecontent, eclipsehelp, htmlhelp, javahelp, odt, pdf, pdf2, tocjs, troff, wordrtf.
set _transtype=html5
for %%v in ( html5 xhtml )   do  if _%1_ EQU _%%v_  set _transtype=%1
for %%v in ( word2dita w2d ) do  if _%1_ EQU _w2d_  set _transtype=word2dita

if _%_gitdir%_      EQU __    set _gitdir=w:\.
if _%_blddir%_      EQU __    set _blddir=v:\bld\%_transtype%
if _%_outdir%_      EQU __    set _outdir=v:\output\%_transtype%
if _%_logdir%_      EQU __    set _logdir=v:\logs
if _%_logfile%_     EQU __    set _logfile=%_logdir%\%_transtype%-test.log
if _%_outext%_      EQU __    set _outext=.html
:. If you change _outext, remember to replace the links in the root index.html

set _expfiles=%~dp0expectedfiles.txt
set _currfiles=%_logdir%\currfiles.txt
set _tempfile=%_logdir%\temp.txt

:. ----- Modify the environment settings above as needed. -----


date /t >%_logfile%

if _%1_ NEQ __ goto %1


:T001
call :header "Checking that all expected files are there."  >> %_logfile%
for /f %%v in ( %_expfiles% ) do if not exist %_outdir%\%%v echo Missing output: %%v >> %_logfile%
call npp %_logfile%
if _%1_ NEQ __ goto :eof


:T002
call :header "Checking new files."  >> %_logfile%
cd /d %_outdir%
dir * /a:-d /s/b > %_tempfile%
echo. > %_currfiles%
for /f %%v in ( %_tempfile% ) do for /f "tokens=4* delims=\" %%w in ( "%%v" ) do @echo %%w\%%x >> %_currfiles%
windiff %_expfiles% %_currfiles%
set /P _ans=Copy the new list? [y/n]
if _%_ans%_ EQU _y_  xcopy %_currfiles% %_expfiles% /v/y
if _%1_ NEQ __ goto :eof


:T003
echo.
echo ------------------------------------------------------------------------
echo In Dr. Link Check, enter http://qa.dnncorp.biz/docs/ and click Start.
echo ------------------------------------------------------------------------
start http://www.drlinkcheck.com/
if _%1_ NEQ __ goto :eof



goto :eof
:header
echo.
echo ---------------------------------------------------------
echo TEST: %1
echo.
goto :eof
