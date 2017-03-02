@echo off

powershell -file mklists.ps1 w:\_content\common\bptext-pbar.dita   pbarbplist.txt
powershell -file mklists.ps1 w:\_content\common\bptext-pbtabs.dita tagsbplist.txt
