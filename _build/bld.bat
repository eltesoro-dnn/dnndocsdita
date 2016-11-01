@echo off
cls
if "%OS%"=="Windows_NT" @setlocal
if "%OS%"=="WINNT" @setlocal


:.----------------------------------------------------------------------------
:. Prerequisites:
:. (You only have to do these once, not per build.)
:. 1. Install Java SE JDK.
:.      http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
:. 2. Download and extract DITA-OT to %DITA_HOME%.
:.      http://www.dita-ot.org/download
:. 3. If running word2dita transform, download and extract the DITA4Publishers plugin to %DITA_HOME%\plugins.
:.      http://github.com/dita4publishers/dita4publishers/releases
:.----------------------------------------------------------------------------



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

if _%_blddir%_      EQU __    set _blddir=v:\%_pref%bld\%_transtype%
if _%_logdir%_      EQU __    set _logdir=v:\%_pref%logs
if _%_outdir%_      EQU __    set _outdir=v:\%_pref%output\%_transtype%
for %%v in ( %* ) do  for %%w in ( 85 )  do  if _%%v_ EQU _%%w_  set _outdir=%_outdir%\85

if _%_logfile%_     EQU __    set _logfile=%_logdir%\%_transtype%.log
if _%_gitdir%_      EQU __    set _gitdir=w:\.
if _%_outext%_      EQU __    set _outext=.html


:. If you change _outext, remember to replace the links in the root index.html

if _"%JAVA_HOME%"_  EQU _""_  set JAVA_HOME=%ProgramFiles%\Java\jdk1.8.0_77
set DITA_HOME=C:\dita-ot
set ANT_HOME=C:\dita-ot

:. ----- Modify the environment settings above as needed. -----



set PATH=%JAVA_HOME%\bin;%DITA_HOME%\bin;%ANT_HOME%\tools\ant\bin;%PATH%
set JAVACMD=java.exe
if exist %JAVA_HOME%\bin\java.exe  set JAVACMD=%JAVA_HOME%\bin\java.exe
call "%DITA_HOME%\resources\env.bat"

echo Recreating build folder, output folder, and logs folder....
for %%v in ( %_blddir% %_outdir% ) do  rd /s/q %%v >nul
for %%v in ( %_blddir% %_outdir% %_logdir% ) do  md %%v >nul
if exist %_logfile%  del %_logfile% /q >nul

goto %_transtype%



:.----------------------------------------------------------------------------
:html5
:xhtml

echo.
echo *========================================================================*
echo  Building docs for %_transtype%%_subbld% - %_bldtype% ....
echo *========================================================================*
echo.

echo Copying files required by the build ....
xcopy %_gitdir%\_content\*.dita*         %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\*.png           %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\*.gif           %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\*.svg           %_blddir%                /i/s/v/y
:. xcopy %_gitdir%\_content\*.mp4           %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\common\samples  %_blddir%\common\samples /i/s/v/y
xcopy %_gitdir%\_themes\dnn\dnn*.css     %_blddir%\_themes\dnn    /i/s/v/y

for %%v in ( administrators developers designers content-managers community-managers ) do  xcopy %_blddir%\common\*.dita* %_blddir%\%%v /i/s/v/y

echo Replacing dita maps and files for %_bldtype% ....
if _%_bldtype%_ NEQ __  powershell -file %_gitdir%\_build\replacefiles.ps1 %_blddir% %_bldtype%


echo Integrating our own DITA-OT plugin ....
rd /s/q %DITA_HOME%\plugins\org.dnn.dc >nul
xcopy %_gitdir%\_build\org.dnn.dc\*.*  %DITA_HOME%\plugins\org.dnn.dc  /i/s/v/y

for %%v in ( %* ) do  for %%w in ( 85 )  do  if _%%v_ EQU _%%w_  (
    echo Replacing xsl files for 85 ....
    powershell -file %_gitdir%\_build\replacefiles.ps1 %DITA_HOME%\plugins\org.dnn.dc 85
)
cd /d   %DITA_HOME%
call ant -f integrator.xml strict


echo Building %_transtype%%_subbld% ....

:. Must start at %DITA_HOME%
cd /d %DITA_HOME%
echo. > %_logfile%
xcopy %_gitdir%\_build\dnn_build*.xml  %DITA_HOME%\.  /v/y
call ant %_transtype%%_subbld% -f %DITA_HOME%\dnn_build.xml -l %_logfile%


:. Test that the build was actually successful.
for %%v in ( administrators developers designers content-managers community-managers ) do  if not exist %_outdir%\%%v\*  goto :ifbuilderror


echo Copying additional required files to the output ....
xcopy %_gitdir%\_content\index*.html         %_outdir%\.                /i/s/v/y
xcopy %_gitdir%\_content\searchresults*.html %_outdir%\.                /i/s/v/y
xcopy %_gitdir%\_content\common\samples      %_outdir%\common\samples   /i/s/v/y
xcopy %_gitdir%\_content\ssi                 %_outdir%\ssi              /i/s/v/y
for %%v in ( jpg png gif svg ) do  xcopy %_gitdir%\_content\common\img\*.%%v    %_outdir%\common\img       /i  /v/y
for %%v in ( jpg png gif svg ) do  xcopy %_gitdir%\_themes\dnn\*.%%v            %_outdir%\_theme           /i/s/v/y
:. for %%v in ( mp4 )             do  xcopy %_gitdir%\_content\common\vid\*.%%v    %_outdir%\common\vid       /i/s/v/y
xcopy %_gitdir%\_themes\dnn\26D3F6*          %_outdir%\_theme           /i/s/v/y
xcopy %_gitdir%\_themes\dnn\*.js             %_outdir%\_theme           /i/s/v/y

del %_outdir%\common\img\*__4gif.png /q

echo Replacing additional required files in the output for %_bldtype% ....
if _%_bldtype%_ NEQ __  powershell -file %_gitdir%\_build\replacefiles.ps1 %_outdir% %_bldtype%


:. The following is a hack.
xcopy %_outdir%\developers\creating-modules\index.html %_outdir%\developers\extensions /v
xcopy %_outdir%\designers\creating-themes\index.html %_outdir%\designers\extensions /v


echo Creating the web.config ....
powershell -file %_gitdir%\_build\urlmap\urlmap.ps1 %_gitdir%\_build\urlmap\DC-URLmapping.csv %_outdir% > %_gitdir%\_content\web.config
xcopy %_gitdir%\_content\web.config          %_outdir%\.                /i/s/v/y


echo Deleting files we don't need ....
if exist %_outdir%\toc.html           del %_outdir%\toc.html /q >nul
if exist %_outdir%\common\glossary\*  rd /s/q %_outdir%\common\glossary >nul


echo Creating an aboutbld.html file ....
for /f "usebackq tokens=2" %%v in (`date /t`) do for /f "delims=/ tokens=1,2,3" %%w in ("%%v") do echo DocCenter v1.3 Build %%y%%w%%x > %_outdir%\aboutbld.html


:. runas /user:administrator /profile "%~f0\v2iis.bat %outdir%\%_transtype% c:\inetpub\wwwroot"
:. start %_outdir%
rd /s /q c:\inetpub\wwwroot\docs
md c:\inetpub\wwwroot\docs
for %%v in ( %_outdir% ) do set cbldir=c:\z\docbuild%%~pnv
echo y | xcopy %cbldir%\* c:\inetpub\wwwroot\docs /i /s /v
start %cbldir%
start c:\inetpub\wwwroot\docs
:. start explorer.exe
:. echo Copy the following to the Windows Explorer address bar: ftp://66.29.195.16/DNN%20Staging/DNNSoftware.QA.Docs/
:. echo In Filezilla, use the following:
:. echo    Host: 66.29.195.16
:. echo    Port: 25
:. echo Use your username and password from Birch.
:. call "C:\Program Files\FileZilla FTP Client\filezilla.exe"

:. TODO: Display error/warn lines in the %_logfile%.


echo Zipping the output ....
powershell -file %_gitdir%\_build\zipbld.ps1 %_outdir%


:ifbuilderror
call npp %_logfile%
goto :eof





:.----------------------------------------------------------------------------
:word2dita
:w2d

echo Copying files required by the build ....
xcopy %_gitdir%\_build\w2d\org.dita4publishers.word2dita  %DITA_HOME%\plugins\org.dita4publishers.word2dita  /i/s/v/y
xcopy %_gitdir%\_content\*.docx                           %_blddir%                                          /i/s/v/y

echo Integrating the Word2DITA DITA-OT plugin ....
cd /d %DITA_HOME%
ant -f integrator.xml strict

echo Building %_transtype% ....

:. Must start at %DITA_HOME%
cd /d %DITA_HOME%
echo. > %_logfile%
for /f "usebackq" %%v in (`dir %_blddir%\*.docx /s /b`) do call ant -f %DITA_HOME%\build.xml -l %_logfile% -Dtranstype=%_transtype% -Dargs.input=%%v -Dargs.output=%_outdir%

:. Copy the results from the hardcoded output directory to our own.
del /q %DITA_HOME%\out\delete.me
xcopy %DITA_HOME%\out %_outdir%\%_transtype% /i /s /v

start %_outdir%\%_transtype%

goto :eof


:.----------------------------------------------------------------------------
