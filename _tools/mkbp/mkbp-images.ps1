# Creates the boilerplates for the Persona Bar images.
# USAGE: powershell -file mkbp-images.ps1 pbar-???.csv > mkbp-images.out
# USAGE:
#   echo. > mkbp-images.out
#   for /f "usebackq" %v in ( `dir pbar-*.csv /b` ) do powershell -file mkbp-images.ps1 %v >> mkbp-images.out

$menusep = "&gt;"
$fnprefix = "pbar-"
$fnsuffix = ".csv"
$asciibase = 64     # 'A' is 65.


function GetProdFromFilename  {
    param( [string] $fn )
    $cleanfn = $fn.TrimStart( $fnprefix ).TrimEnd( $fnsuffix )
    return $cleanfn.Substring( 0, 3 )
}

function GetPersonaFromFilename  {
    param( [string] $fn )
    $cleanfn = $fn.TrimStart( $fnprefix ).TrimEnd( $fnsuffix )
    return $cleanfn.Substring( 3, $cleanfn.Length - 3 )
}


function MkBlurb  {
    param( [string] $prod, [string] $persona, [string] $menu1, [string] $menu2, [string] $pos )

    $cascadealt = "Persona Bar $menusep $menu1"
    if ( $menu2 -ne "" )  {
        $cascadealt = "Persona Bar $menusep $menu1 $menusep $menu2"
    }

    $classol = "olpb" + $prod + $pos

    $menu1squashed = $menu1.Replace( " ", "" )

    $menu2squashed = ""
    $bpid = "image-pb-$persona-$menu1squashed-$prod"
    if ( $menu2 -ne "" )  {
        $menu2squashed = $menu2.Replace( " ", "" ).Replace( ".NET", "NET" )
        $bpid  = "image-pb-$persona-$menu1squashed-$menu2squashed-$prod"
    }

    $imgfn = "scr-pbar-$persona-$menu1squashed-$prod.png"

    Write-Host( "" )
    Write-Host( "" )
    Write-Host( "            <!-- <image conkeyref=""k-bpimages/$bpid""><cmd/></image> -->" )
    Write-Host( "            <image id=""$bpid"" outputclass=""img-scr-menu $classol"" scalefit=""yes"" placement=""break"" align=""left"" href=""img/$imgfn""><alt>$cascadealt</alt></image>" )
}


# MAIN
if ( $args.Count -gt 0 )  {
    $srccsv = $args[0]
    $prod = GetProdFromFilename $srccsv
    $persona = GetPersonaFromFilename $srccsv

    Write-Host( "" )
    Write-Host( "" )
    Write-Host( "        <!-- This section was generated by running: powershell -file mkbp-images.ps1 $srccsv > mkbp-images.out -->" )
    Write-Host( "        <!-- START SECTION -->" )

    # Process each persona.

    Write-Host( "" )
    Write-Host( "" )
    Write-Host( "        <!-- ==================== $prod - $persona ==================== -->" )
    $i = $asciibase
    $j = $asciibase
	foreach ( $ln in ( Import-Csv $srccsv ) )  {
        if ( $ln.menu2 -eq "" )  {
            $i++
            $j = $asciibase
            $pos = [char]$i
        }
        else  {
            $j++
            $pos = [char]$i + [char]$j
        }
        MkBlurb $prod $persona $ln.menu1 $ln.menu2 $pos
    }


}
