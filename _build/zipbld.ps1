# Zips the output folder.
# USAGE:    powershell -file w:\_build\zipbld.ps1 <sourcedir>
# Example:  powershell -file w:\_build\zipbld.ps1 v:\output\html5

#default, if no parameters
$src = v:\output\html5

if ( $args.Count -gt 0 )  {
    $src = $args[0]
}

$index = $src.LastIndexOf( "\" )
$srcdir = $src.Substring( 0, $index )
$fn = $src.Substring( $index + 1, $args[0].Length - $index - 1 )

$now = Get-Date -Format "yyyyMMddHHmm"
$tgtzip = "$srcdir\$now-$fn.zip"
if ( test-path $tgtzip )  { remove-item $tgtzip }
Write-Host( "Zipping to $tgtzip....")

compress-archive -Path $srcdir -DestinationPath $tgtzip
