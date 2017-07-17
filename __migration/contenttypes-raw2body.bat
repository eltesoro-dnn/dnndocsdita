@echo off

powershell -file contenttypes-raw2body.ps1 raw.out out\jobs-contenttypes.out
windiff json\jobs-contenttypes.json out\jobs-contenttypes.out
call npp out\jobs-contenttypes.out
