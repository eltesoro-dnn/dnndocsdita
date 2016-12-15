@echo off
:. if _%1_ EQU __ goto :usage

powershell -file mkcp2pb.ps1 menus-cp2pb.csv > cp2pb.out
npp cp2pb.out

goto :eof

:usage
echo USAGE: %0 menus-cp2pb.csv
