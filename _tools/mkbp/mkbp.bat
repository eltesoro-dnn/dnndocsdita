@echo off
if _%1_ EQU __  goto :usage
goto %1


:roles
call %0 runme json\roles.json bptext-rolessteps W:\_content\common\roles prolog.txt
goto :eof

:sites
call %0 runme json\sites.json bptext-sites W:\_content\administrators\sites prolog.txt
goto :eof

:search
call %0 runme json\search.json bptext-search W:\_content\common\search prolog.txt
:. robocopy W:\_tools\mkbp\out W:\_content\common\search *.dita /xf bptext-search-tmp.dita /mt
:. Explorer W:\_tools\mkbp\out
:. Explorer W:\_content\common\search
goto :eof

:vocab
:vocabularies
call %0 runme json\vocabularies.json bptext-vocabularies W:\_content\common\vocabularies prolog.txt
goto :eof

:servers
call %0 runme json\servers.json bptext-servers W:\_content\common\servers prolog-CE.txt
goto :eof

:sitelogs
call %0 runme json\sitelogs.json      bptext-sitelogs      W:\_content\common\sitelogs
goto :eof


:tested

:content
call %0 runme json\content.json       bptext-content       W:\_content\common\structured-content
goto :eof

:import-export
:importexport
call %0 runme json\import-export.json bptext-import-export W:\_content\administrators\import-export
goto :eof


:wip

:urlmanagement
call %0 runme json\urlmanagement.json bptext-urlmanagement W:\_content\common\urlmanagement prolog-PCE.txt
goto :eof

:analytics
call %0 runme json\analytics.json bptext-analytics W:\_content\common\analytics json\analytics-prolog.txt
goto :eof



:runme
if _%3_ EQU __  goto :error
cd /d %~dp0
if not exist %~dp0out\*  md %~dp0out > nul
del %~dp0out\* /q
powershell -file mkbp-json.ps1 %2 %3 %~dp0out %5
call windiff %4\* %~dp0out\*
start %4
start %~dp0out
npp %4\bp* %~dp0out\bp*
goto :eof
:. powershell -file mkbp-compare-copy.ps1
:. for /f "usebackq" %%v in (`dir out-%1\*.dita /b`) do fc W:\_content\common\roles\%%v out-%1\%%v
:. for /f "usebackq" %%v in (`dir out-%1\*.dita /b`) do if _%%v_ NEQ _bptext-rolessteps.dita_ xcopy out-%1\%%v W:\_content\common\roles /v /y
:. for /f "usebackq" %v in (`dir out-%1\*.dita /b`) do if _%v_ NEQ _bptext-rolessteps.dita_ xcopy out-%1\%v W:\_content\common\roles /v /y



:error
echo.
echo ERROR: Insufficient parameters in internal call.
goto :eof

:usage
echo.
echo USAGE: %0 folder
echo EXAMPLE: %0 roles
goto :eof
