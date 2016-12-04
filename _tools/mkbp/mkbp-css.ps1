# Creates the CSS variables for the Persona Bar images.
# USAGE:   powershell -file mkbp-css.ps1 pbar-E90host.csv > mkbp-css.out
# EXAMPLE: powershell -file mkbp-css.ps1 pbar-E90host.csv > mkbp-css.out


$menusep = "&gt;"
$fnprefix = "pbar-"
$fnsuffix = ".csv"
$asciibase = 64     # 'A' is 65.
$px = "px"



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
    param( [string] $prod, [string] $persona, [string] $menu1, [string] $menu2, [string] $left1, [string] $top1, [string] $left2, [string] $top2 )

    $menu1squashed = $menu1.Replace( " ", "" )

    $menu2squashed = ""
    $bpid = "pb-$persona-$menu1squashed-$prod"
    if ( $menu2 -ne "" )  {
        $menu2squashed = $menu2.Replace( " ", "" ).Replace( ".NET", "NET" )
        $bpid  = "pb-$persona-$menu1squashed-$menu2squashed-$prod"
    }

    if ( $menu2 -eq "" )  {
        Write-Host( ".olpb1-$menu1squashed-$prod$persona  { color: var( --color-overlay ); font-size: 300%; position: absolute; left: $left1$px; top: $top1$px; }" )
    }
    else  {
        Write-Host( ".olpb2-$menu1squashed-$menu2squashed-$prod$persona  { color: var( --color-overlay ); font-size: 300%; position: absolute; left: $left2$px; top: $top2$px; }" )
    }

}


# MAIN
if ( $args.Count -gt 0 )  {
    $srccsv = $args[0]
    $prod = GetProdFromFilename $srccsv
    $persona = GetPersonaFromFilename $srccsv

    Write-Host( "" )
    Write-Host( "" )
    Write-Host( " /*" )
    # Write-Host( " | -------------------- $prod - $persona --------------------" )
    Write-Host( " | This section was generated by running: powershell -file mkbp-css.ps1 $srccsv > mkbp-css.out" )
    Write-Host( " | Persona Bar arrow positions" )
    Write-Host( " */" )
    Write-Host( "" )

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
        MkBlurb $prod $persona $ln.menu1 $ln.menu2 $ln.left1 $ln.top1 $ln.left2 $ln.top2
    }
}