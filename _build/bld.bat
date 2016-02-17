@echo off
cls

if "%OS%"=="Windows_NT" @setlocal
if "%OS%"=="WINNT" @setlocal


:. ----- Modify the environment settings below as needed. -----

:. Choose one output format or specify it in as the first parameter to this batch file.
:. Currently available: html5, xhtml.
:. Future options: common-html, docbook, eclipsecontent, eclipsehelp, htmlhelp, javahelp, odt, pdf, pdf2, tocjs, troff, wordrtf.
set _transtype=html5
for %%v in ( html5 xhtml ) do  if _%1_ EQU _%%v_  set _transtype=%1

if _%_gitdir%_      EQU __    set _gitdir=w:\.
if _%_blddir%_      EQU __    set _blddir=v:\bld
if _%_outdir%_      EQU __    set _outdir=v:\output
if _%_logdir%_      EQU __    set _logdir=v:\logs

if _%DITA_HOME%_    EQU __    set DITA_HOME=C:\dita-ot
if _%ANT_HOME%_     EQU __    set ANT_HOME=C:\dita-ot
if _"%JAVA_HOME%"_  EQU _""_  set JAVA_HOME="%ProgramFiles%"\Java\jdk1.8.0_72

:. ----- Modify the environment settings above as needed. -----


set PATH=%JAVA_HOME%\bin;%DITA_HOME%\bin;%ANT_HOME%\tools\ant\bin;%PATH%
set JAVACMD=java.exe
if exist %JAVA_HOME%\bin\java.exe  set JAVACMD=%JAVA_HOME%\bin\java.exe
call "%DITA_HOME%\resources\env.bat"


echo Deleting build folder, output folder, and logs folder....
for %%v in ( %_blddir% %_outdir% %_logdir% ) do rd /s/q %%v >nul


echo Copying files required by the build ....
xcopy %_gitdir%\_content\*.dita*         %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\*.png           %_blddir%                /i/s/v/y
xcopy %_gitdir%\_content\common\samples  %_blddir%\common\samples /i/s/v/y
xcopy %_gitdir%\_themes\dnn\dnn*.css     %_blddir%\_themes\dnn    /i/s/v/y


echo Integrating our own DITA-OT plugin ....
rd /s/q %DITA_HOME%\plugins\org.dnn.dc >nul
xcopy %_gitdir%\_build\org.dnn.dc\*.*  %DITA_HOME%\plugins\org.dnn.dc  /i/s/v/y
cd /d   %DITA_HOME%
call ant -f integrator.xml strict


echo bld.bat: Building %_transtype% ....

:. Must start at %DITA_HOME%
cd /d %DITA_HOME%
md %_logdir% > nul
echo. > %_logdir%\log.txt
xcopy %_gitdir%\_build\dnn_build.xml  %DITA_HOME%\.  /v/y
call ant %_transtype% -f %DITA_HOME%\dnn_build.xml -l %_logdir%\log.txt


echo Copying additional files required to the output ....
xcopy %_gitdir%\_content\common\samples   %_outdir%\%_transtype%\common\samples   /i/s/v/y
xcopy %_gitdir%\_content\common\img\*.png %_outdir%\%_transtype%\common\img       /i/s/v/y
xcopy %_gitdir%\_themes\dnn\26D3F6_6_0.*  %_outdir%\%_transtype%\_theme           /i/s/v/y
xcopy %_gitdir%\_themes\dnn\*.jpg         %_outdir%\%_transtype%\_theme           /i/s/v/y
xcopy %_gitdir%\_themes\dnn\*.js          %_outdir%\%_transtype%\_theme           /i/s/v/y


:. runas /user:administrator /profile "%~f0\v2iis.bat %outdir%\%_transtype% c:\inetpub\wwwroot"
start %_outdir%\%_transtype%
start c:\inetpub\wwwroot
