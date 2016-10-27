# Copies the 4live maps to their counterparts.
# USAGE: powershell -file w:\_build\replacefiles.ps1 v:\bld 4live

if ( $args.Count -gt 1 )  {
	$ctndir = $args[0]
	$bldtype = "-" + $args[1]

  	Write-Host All files:
    foreach ( $fn in Get-ChildItem -path $ctndir -include *$bldtype.* -recurse )
	{
		Write-Host
		Write-Host Copying $fn.FullName
		Write-Host 	    to $fn.FullName.Replace( $bldtype, "" )
		#Copy-Item -LiteralPath $fn.FullName -Destination $fn.FullName.Replace( $bldtype, "" ) -Force
		Move-Item -LiteralPath $fn.FullName -Destination $fn.FullName.Replace( $bldtype, "" ) -Force
	}
}