@echo off

goto postmeta
    This file is part of the DITA Open Toolkit project.
    See the accompanying license.txt file for applicable licenses.

    Derived from Apache Ant command line tool.

    Licensed to the Apache Software Foundation (ASF) under one or more
    contributor license agreements.  See the NOTICE file distributed with
    this work for additional information regarding copyright ownership.
    The ASF licenses this file to You under the Apache License, Version 2.0
    (the "License"); you may not use this file except in compliance with
    the License.  You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
:postmeta


if "%OS%"=="Windows_NT" @setlocal
if "%OS%"=="WINNT" @setlocal

if "%DITA_HOME%"=="" set DITA_HOME="%~dp0.."

set ANT_HOME=C:\dita-ot-2.2.1
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_72
set PATH=%ANT_HOME%\bin;%DITA_DIR%tools\ant\bin;%JAVA_HOME%\bin;%PATH%


:. Slurp the command line arguments. This loop allows for an unlimited number of arguments (up to the command line limit, anyway).
set DITA_CMD_LINE_ARGS=
:setupArgs
if ""%1""=="""" goto doneStart
set DITA_CMD_LINE_ARGS=%DITA_CMD_LINE_ARGS% %1
shift
goto setupArgs
:doneStart


:checkJava
call "%DITA_HOME%\resources\env.bat"

set _JAVACMD=%JAVACMD%

if "%JAVA_HOME%" == "" goto noJavaHome
if not exist "%JAVA_HOME%\bin\java.exe" goto noJavaHome
if "%_JAVACMD%" == "" set _JAVACMD=%JAVA_HOME%\bin\java.exe

:noJavaHome
if "%_JAVACMD%" == "" set _JAVACMD=java.exe


:runAnt
"%_JAVACMD%" %ANT_OPTS% -classpath "%DITA_HOME%\lib\ant-launcher.jar" "-Dant.home=%DITA_HOME%"  "-Ddita.dir=%DITA_HOME%" org.apache.tools.ant.launch.Launcher %ANT_ARGS% -cp "%CLASSPATH%" %DITA_CMD_LINE_ARGS% -buildfile "%DITA_HOME%\build.xml" -main "org.dita.dost.invoker.Main"


:. Check the error code of the Ant build
:. if not "%OS%"=="Windows_NT" goto onError
set ANT_ERROR=%ERRORLEVEL%
goto endError


:onError
rem Windows 9x way of checking the error code.  It matches via brute force.
for %%i in (1 10 100) do set err%%i=
for %%i in (0 1 2) do if errorlevel %%i00 set err100=%%i
if %err100%==2 goto onError200
if %err100%==0 set err100=
for %%i in (0 1 2 3 4 5 6 7 8 9) do if errorlevel %err100%%%i0 set err10=%%i
if "%err100%"=="" if %err10%==0 set err10=
:onError1
for %%i in (0 1 2 3 4 5 6 7 8 9) do if errorlevel %err100%%err10%%%i set err1=%%i
goto onErrorEnd
:onError200
for %%i in (0 1 2 3 4 5) do if errorlevel 2%%i0 set err10=%%i
if err10==5 for %%i in (0 1 2 3 4 5) do if errorlevel 25%%i set err1=%%i
if not err10==5 goto onError1
:onErrorEnd
set ANT_ERROR=%err100%%err10%%err1%
for %%i in (1 10 100) do set err%%i=
:endError

rem bug ID 32069: resetting an undefined env variable changes the errorlevel.
if not "%_JAVACMD%"=="" set _JAVACMD=
if not "%_DITA_CMD_LINE_ARGS%"=="" set DITA_CMD_LINE_ARGS=

if "%ANT_ERROR%"=="0" goto mainEnd

goto omega


:mainEnd
rem If there were no errors, we run the post script.
if "%OS%"=="Windows_NT" @endlocal
if "%OS%"=="WINNT" @endlocal

:omega

exit /b %ANT_ERROR%
