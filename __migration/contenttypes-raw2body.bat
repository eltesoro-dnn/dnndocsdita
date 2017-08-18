@echo off

powershell -file contenttypes-raw2body.ps1 contenttype-raw.out out\jobs-contenttypes.out
windiff json\jobs-contenttypes.json out\jobs-contenttypes.out

set /p _ans_=Copy out\jobs-contenttypes.out to json\jobs-contenttypes.json? [n/y]
if _%_ans_%_ EQU _y_  xcopy out\jobs-contenttypes.out json\jobs-contenttypes.json /v /y

call npp out\jobs-contenttypes.out
