@echo off

echo In the green-room site, manually add a new content type or update an existing one.
pause

echo Generating raw.out. . . .
call dnnps listall-contenttypes

echo Updating jobs-contenttypes.json. . . .
call contenttypes-raw2body.bat

echo Update createcontenttypes.bat with the new content type, if any.
echo    To add:     dnnps add-contenttype-nameofnewtype
echo    To update:  dnnps update-contenttype-nameoftypetoupdate
call npp createcontenttypes.bat
pause

call dnnps listall-contenttypes
