# Checks if the image mentioned in a .dita file exists.
# USAGE: powershell -file w:\_test\get-mentioned-images.ps1 w:\_content w:\_content\common\img

$ctndir = $args[0]
$imgdir = $args[1]

Write-Host Missing files:
foreach ( $file in Get-ChildItem -path $ctndir -include *.dita -recurse )
{
	foreach ( $imagecall in ( Get-Content $file | Select-String -pattern "scr[a-zA-Z0-9_-]+.png" -AllMatches | Select-String -pattern "<!--" -notmatch | %{ $_.Matches } | %{ $_.Value } ) )
	{
		# if the image does not exist
		if ( -not ( Test-Path $imgdir\$imagecall ) )
		{
			Write-Host <#$file.fullname:#> $imagecall
		}
	}
}
