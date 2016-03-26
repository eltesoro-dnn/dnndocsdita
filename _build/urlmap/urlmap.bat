@echo off
setlocal ENABLEDELAYEDEXPANSION

:. web.config template from Nathan

set _urlmap=urlmap.txt
set _log=web.config

echo [?xml version="1.0" encoding="UTF-8"?] > %_log%
echo [configuration] >> %_log%
echo     [system.webServer] >> %_log%
echo         [rewrite] >> %_log%
echo            [rules] >> %_log%
echo                [clear /] >> %_log%

:. This changes the URL to lowercase for SEO purposes. (Code from Nathan Rover.)
echo                [rule name="LowerCaseRule1" stopProcessing="true"] >> %_log%
echo                    [match url="[A-Z]" ignoreCase="false" /] >> %_log%
echo                    [action type="Redirect" redirectType="301" url="{ToLower:{URL}}" /] >> %_log%
echo                [/rule] >> %_log%

:. Check the second parameter because "for" ignores blank first tokens.
for /f "tokens=1,2,3" %%u in ( %_urlmap% ) do  if _%%w_ NEQ __  (
    echo                [rule name="%%u" stopProcessing="true"] >> %_log%
    echo                   [match url="^(.*)%%v$" /] >> %_log%
    for /f "tokens=1 delims=:" %%m in ( "%%w" ) do  (
        set _prefix={R:1}
        if _%%m_ EQU _http_  set _prefix=
        if _%%m_ EQU _https_ set _prefix=
        echo                   [action type="Redirect" url="!_prefix!%%w" /] >> %_log%
    )
    echo                [/rule] >> %_log%
)

echo            [/rules] >> %_log%
echo         [/rewrite] >> %_log%
echo     [/system.webServer] >> %_log%
echo [/configuration] >> %_log%

echo ----------------------------------------------------------------------------------------------
echo IMPORTANT: Edit %_log% to replace the square brackets [] and make it a valid XML file.
echo ----------------------------------------------------------------------------------------------
if _%USERNAME%_ EQU _eleanor.tesoro_  call npp %_log%
goto :eof

