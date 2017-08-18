@echo off

echo In the green-room site, manually add a new content type or update an existing one.
pause

echo Generating raw.out. . . .
call dnnps listall-contenttypes %bldsite%

echo Updating jobs-contenttypes.json. . . .
call contenttypes-raw2body.bat

echo Update createcontenttypes.bat with the new content type, if any.
echo    To add:     dnnps add-contenttype-nameofnewtype %bldsite%
echo    To update:  dnnps update-contenttype-nameoftypetoupdate %bldsite%
call npp createcontenttypes.bat
pause

call dnnps listall-contenttypes %bldsite%
