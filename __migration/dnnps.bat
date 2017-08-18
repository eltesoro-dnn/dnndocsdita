@echo off
setlocal

if _%4_ EQU __  ( if _%bldsite%_ EQU __  goto :usage )


:. default settings
set jobname=listall-contenttypes
set settingsjson=internal\settings-doccenter-%bldsite%.json
set jobsfiles=json\jobs*.json
set asseturlsfile=internal\assets-%bldsite%.txt

:. settings from parameters
if _%1_ NEQ __  set jobname=%1
if _%2_ NEQ __  set jobsfiles=%2
if _%3_ NEQ __  set settingsjson=%3
if _%4_ NEQ __  set asseturlsfile=%4


echo *** powershell -file dnnps.ps1 %jobname% %jobsfiles% %settingsjson% %asseturlsfile%
powershell -file dnnps.ps1  %jobname% %jobsfiles% %settingsjson% %asseturlsfile%
goto :eof


:usage
echo USAGE:    %0 jobname jobsfiles settingsjson asseturlsfile
echo           NOTE: You can also set the evar 'bldsite' to use the default settings.
echo EXAMPLES:
echo           %0 listall-contenttypes json\jobs*.json json\settings-updated.json json\assets.txt
echo           %0 listall-contenttypes json\jobs*.json
echo           %0 listall-contenttypes
goto :eof
