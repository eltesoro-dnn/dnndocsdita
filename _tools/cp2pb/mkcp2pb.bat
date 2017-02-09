@echo off

powershell -file mkcp2pb.ps1 menus-cp2pb.csv menus-cp2pb.out W:\_content\common\control-bar-to-persona-bar.dita
npp menus-cp2pb.out
npp w:\_content\common\control-bar-to-persona-bar.dita

goto :eof

