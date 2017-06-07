@echo off
cls

:. Set to blank if you don't care about zipping the build files.
set _zipoutdir=

:. Path to the text editor of your choice.
set _texteditor=%ProgramFiles%\Notepad++\notepad++.exe

:. Path to the docs folder in your local website.
set _localhostdocdir=c:\inetpub\wwwroot\docs

:. Mapped drive to the build folder.
set _bldroot=v:

:. Mapped drive to the source files.
set _gitroot=w:

:. Java JDK version. Keep the same format.
set _javajdkver=jdk1.8.0_121

:. Path to Java folder.
set JAVA_HOME=%ProgramFiles%\Java\%_javajdkver%

:. Path to DITA-OT. The files will be extracted here.
set DITA_HOME=C:\dita-ot



:. Call to PS script
powershell -file %_gitroot%\_build\bld.ps1
