# Replaces "/docs/" with "/docs/85/" in all html files.
# USAGE:
#   xcopy v:\20160916 v:\20160916-85 /s /v
#   powershell -file w:\_build\replacedocswithdocs85.ps1 v:\20160916-85
if ( $args.Count -gt 0 )  {
	$ctndir = $args[0]

    $oldstr = "/docs"
    $newstr = "/docs/85"

    Write-Host In path $ctndir ...
    foreach ( $fn in Get-ChildItem -path $ctndir -include *.html -recurse )
	{
		Write-Host Replacing strings in $fn.FullName ...
        ( Get-Content $fn ) | foreach-object { $_.Replace( $oldstr, $newstr ) } | Set-Content $fn
	}
}
