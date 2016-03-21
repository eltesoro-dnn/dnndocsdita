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
:. 3. If running word2dita transform,
:.    a. Download and extract the DITA4Publishers plugin to %DITA_HOME%\plugins.
:.          https://github.com/dita4publishers/dita4publishers/releases
:.    b. Integrate the plugin.
:.          cd /d %DITA_HOME%
:.          ant -f integrator.xml strict
:.----------------------------------------------------------------------------



:. ----- Modify the environment settings below as needed. -----

:. Choose one output format or specify it in as the first parameter to this batch file.
:. Currently available: html5, xhtml, word2dita.
:. Future options: common-html, docbook, eclipsecontent, eclipsehelp, htmlhelp, javahelp, odt, pdf, pdf2, tocjs, troff, wordrtf.
set _transtype=html5
for %%v in ( html5 xhtml )   do  if _%1_ EQU _%%v_  set _transtype=%1
for %%v in ( word2dita w2d ) do  if _%1_ EQU _w2d_  set _transtype=word2dita

set _subbld=
for %%v in ( adm dev dsg )   do  if _%1_ EQU _%%v_  set _subbld=-%1

if _%_gitdir%_      EQU __    set _gitdir=w:\.
if _%_blddir%_      EQU __    set _blddir=v:\bld\%_transtype%
if _%_outdir%_      EQU __    set _outdir=v:\output\%_transtype%
if _%_logdir%_      EQU __    set _logdir=v:\logs
if _%_logfile%_     EQU __    set _logfile=%_logdir%\%_transtype%.log
if _%_outext%_      EQU __    set _outext=.html
:. Remember to replace the links in the root index.html

if _"%JAVA_HOME%"_  EQU _""_  set JAVA_HOME="%ProgramFiles%"\Java\jdk1.8.0_72
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

echo Copying files required by the build ....
xcopy %_gitdir%\_content\*.dita*         %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\*.png           %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\common\samples  %_blddir%\common\samples /i/s/v/y
xcopy %_gitdir%\_themes\dnn\dnn*.css     %_blddir%\_themes\dnn    /i/s/v/y

for %%v in ( Administrators Developers Designers ) do  xcopy %_blddir%\common\*.dita* %_blddir%\%%v /i/s/v/y

echo Integrating our own DITA-OT plugin ....
rd /s/q %DITA_HOME%\plugins\org.dnn.dc >nul
xcopy %_gitdir%\_build\org.dnn.dc\*.*  %DITA_HOME%\plugins\org.dnn.dc  /i/s/v/y
cd /d   %DITA_HOME%
call ant -f integrator.xml strict


echo Building %_transtype%%_subbld% ....

:. Must start at %DITA_HOME%
cd /d %DITA_HOME%
echo. > %_logfile%
xcopy %_gitdir%\_build\dnn_build.xml  %DITA_HOME%\.  /v/y
call ant %_transtype%%_subbld% -f %DITA_HOME%\dnn_build.xml -l %_logfile%


echo Copying additional files required to the output ....
xcopy %_gitdir%\_content\index.html          %_outdir%\.                /i/s/v/y
xcopy %_gitdir%\_content\searchresults.html  %_outdir%\.                /i/s/v/y
xcopy %_gitdir%\_content\common\samples      %_outdir%\common\samples   /i/s/v/y
xcopy %_gitdir%\_content\common\img\*.png    %_outdir%\common\img       /i/s/v/y
xcopy %_gitdir%\_themes\dnn\26D3F6_6_0.*     %_outdir%\_theme           /i/s/v/y
xcopy %_gitdir%\_themes\dnn\*.jpg            %_outdir%\_theme           /i/s/v/y
xcopy %_gitdir%\_themes\dnn\*.png            %_outdir%\_theme           /i/s/v/y
xcopy %_gitdir%\_themes\dnn\*.js             %_outdir%\_theme           /i/s/v/y

:. The following is a hack.
xcopy %_outdir%\Developers\CreatingModules\index.html %_outdir%\Developers\Extensions /v
xcopy %_outdir%\Designers\CreatingThemes\index.html %_outdir%\Designers\Extensions /v


echo Deleting files we don't need ....
if exist %_outdir%\toc.html           del %_outdir%\toc.html /q >nul
if exist %_outdir%\common\glossary\*  rd /s/q %_outdir%\common\glossary >nul



:. runas /user:administrator /profile "%~f0\v2iis.bat %outdir%\%_transtype% c:\inetpub\wwwroot"
:. start %_outdir%
start c:\z\docbuild\output\%_transtype%
start c:\inetpub\wwwroot\docs

goto :eof


:.----------------------------------------------------------------------------
:word2dita
:w2d

echo Copying files required by the build ....
xcopy %_gitdir%\_build\w2d\build.properties     %DITA_HOME%           /v/y
xcopy %_gitdir%\_content\*.docx                 %_blddir%         /i/s/v/y

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
