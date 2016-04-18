@echo off
@setlocal

set _urlmap=urlmap.txt
set _site=http://qa.dnncorp.biz/docs

if _%1_ NEQ __ goto %1

:testall
:. Check the second parameter because "for" ignores blank first tokens.
for /f "tokens=2,3" %%v in ( %_urlmap% ) do  if _%%w_ NEQ __  (
    echo Calling %_site%/%%v
    start %_site%/%%v
    pause
)

:testonly
for /f "tokens=1,2" %%u in ( %_urlmap% ) do  if _%%u_ EQU _testonly_  (
    echo Calling %_site%/%%v
    start %_site%/%%v
    pause
)