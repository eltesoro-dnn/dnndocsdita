@echo off
cls
if "%OS%"=="Windows_NT" @setlocal
if "%OS%"=="WINNT" @setlocal

:. ----- Modify the environment settings below as needed. -----

:. Choose one output format or specify it in as the first parameter to this batch file.
:. Currently available: html5, xhtml, word2dita.
:. Future options: common-html, docbook, eclipsecontent, eclipsehelp, htmlhelp, javahelp, odt, pdf, pdf2, tocjs, troff, wordrtf.
set _transtype=html5
for %%v in ( %* ) do  for %%w in ( html5 xhtml )           do  if _%%v_ EQU _%%w_  set _transtype=%%w
for %%v in ( %* ) do  for %%w in ( word2dita w2d )         do  if _%%v_ EQU _%%w_  set _transtype=word2dita

set _subbld=
for %%v in ( %* ) do  for %%w in ( adm dev dsg cmg mod )   do  if _%%v_ EQU _%%w_  set _subbld=-%1

set _bldtype=
set _pref=
for %%v in ( %* ) do  for %%w in ( 4live )                 do  if _%%v_ EQU _%%w_  (
	set _bldtype=%%w
	set _pref=%%w-
)

if _%_gitdir%_      EQU __    set _gitdir=w:\.
if _%_blddir%_      EQU __    set _blddir=v:\%_pref%bld\%_transtype%
if _%_outdir%_      EQU __    set _outdir=v:\%_pref%output\%_transtype%
if _%_logdir%_      EQU __    set _logdir=v:\%_pref%logs
if _%_logfile%_     EQU __    set _logfile=%_logdir%\%_transtype%-test.log
if _%_outext%_      EQU __    set _outext=.html
:. If you change _outext, remember to replace the links in the root index.html

set _imgdir=%_gitdir%\_content\common\img
set _tstdir=%_gitdir%\_test
set _expfiles=%~dp0expectedfiles.txt
set _currfiles=%_logdir%\currfiles.txt
set _tempfile=%_logdir%\temp.txt
set _staging=http://qa.dnncorp.biz/docs/

set _urlmap=W:\_build\urlmap\urlmap.txt
set _site=http://qa.dnncorp.biz/docs

:. ----- Modify the environment settings above as needed. -----


date /t >%_logfile%


:T001
call :header "Checking that all expected files are there."  >> %_logfile%
for /f %%v in ( %_expfiles% ) do if not exist %_outdir%\%%v echo Missing output: %%v >> %_logfile%
call npp %_logfile%
:. if _%1_ NEQ __ goto :eof


:T002
call :header "Checking new files."  >> %_logfile%
cd /d %_outdir%
dir * /a:-d /s/b > %_tempfile%
echo. > %_currfiles%
for /f %%v in ( %_tempfile% ) do for /f "tokens=4* delims=\" %%w in ( "%%v" ) do @echo %%w\%%x >> %_currfiles%
echo foo.txt >> %_currfiles%
windiff %_expfiles% %_currfiles%
set /P _ans=Copy the new list? [y/n]
if _%_ans%_ EQU _y_  xcopy %_currfiles% %_expfiles% /v/y
:. if _%1_ NEQ __ goto :eof


:T003
call :header In Dr. Link Check, enter http://qa.dnncorp.biz/docs/ and click Start."  >> %_logfile%
start http://www.drlinkcheck.com/
:. if _%1_ NEQ __ goto :eof


:T004
call :header "Verifying that mentioned images exist."  >> %_logfile%
powershell -file %_tstdir%\get-mentioned-images.ps1 %_gitdir% %_imgdir% >> %_logfile%
call npp %_logfile%
:. if _%1_ NEQ __ goto :eof


goto :eof
:T005 - Not yet tested.
call :header "Testing win.config."  >> %_logfile%
:testall
:. Check the second parameter because "for" ignores blank first tokens.
for /f "tokens=2,3" %%v in ( %_urlmap% ) do  if _%%w_ NEQ __  (
    echo Testing URL %_site%/%%v  >> %_logfile%
    curl %_site%/%%w > %_tempfile%
    if ( _%%x_ NEQ __ )
		comp %_staging%/%_tempfile% %%x /a /l /n:3  >> %_logfile%
)
:testonly
for /f "tokens=1,2" %%u in ( %_urlmap% ) do  if _%%u_ EQU _testonly_  (
    echo Testing URL %_site%/%%v  >> %_logfile%
    start %_site%/%%v > %_tempfile%
    if ( _%%x_ NEQ __ )
		comp %_staging%/%_tempfile% %%x /a /l /n:3  >> %_logfile%
)
:. if _%1_ NEQ __ goto :eof


goto :eof
:header
echo.
echo ---------------------------------------------------------
echo TEST: %1
echo.
goto :eof
