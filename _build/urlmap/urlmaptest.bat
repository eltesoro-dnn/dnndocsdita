@echo off
@setlocal

set _urlmap=urlmap.txt
set _site=http://qa.dnncorp.biz/docs

:. Check the second parameter because "for" ignores blank first tokens.
for /f "tokens=1,2,3" %%u in ( %_urlmap% ) do  if _%%w_ NEQ __  (
    echo Calling %_site%/%%v
    start %_site%/%%v
    pause
)
