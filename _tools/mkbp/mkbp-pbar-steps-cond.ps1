# Creates the boilerplates for the Persona Bar images.
# USAGE: powershell -file mkbp-pbar-steps-cond.ps1 pbar-???.csv > mkbp-pbar-steps.out
# USAGE:
#   echo. > mkbp-pbar-steps.out
#   for /f "usebackq" %v in ( `dir pbar-*.csv /b` ) do powershell -file mkbp-pbar-steps-cond.ps1 %v >> mkbp-pbar-steps.out
# EXAMPLE: powershell -file mkbp-pbar-steps-cond.ps1 pbar-E90host.csv > mkbp-pbar-steps.out
#
# WARNINGS:
#   * For overlays on the image:
#       - Do NOT use "align=". It creates a <div> around the image.
#       - Do NOT use "placement="break"". It adds <br/> before and after the image.


$menusep = "&gt;"
$fnprefix = "pbar-"
$fnsuffix = ".csv"
$asciibase = 64     # 'A' is 65.
$pbicon1 = "&#10122;"
$pbicon2 = "&#10123;"


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
    param( [string] $prod, [string] $persona, [string] $menu1, [string] $menu2 )

    $cascadealt = "Persona Bar $menusep $menu1"
    if ( $menu2 -ne "" )  {
        $cascadealt = "Persona Bar $menusep $menu1 $menusep $menu2"
    }

    $menu1squashed = $menu1.Replace( " ", "" )

    $menu2squashed = ""
    $bpid = "pb-$persona-$menu1squashed-$prod"
    if ( $menu2 -ne "" )  {
        $menu2squashed = $menu2.Replace( " ", "" ).Replace( ".NET", "NET" )
        $bpid  = "pb-$persona-$menu1squashed-$menu2squashed-$prod"
    }

    $imgfn = "scr-pbar-$persona-$menu1squashed-$prod.png"

    Write-Host( "" )
    Write-Host( "" )
    Write-Host( "           <!-- <step conref=""bptext-pbar.dita#tsk-bptext-pbar/step-$bpid""><cmd/></step> -->" )
    Write-Host( "           <!-- <step conkeyref=""k-bppbar/step-$bpid""><cmd/></step> -->" )
    Write-Host( "           <!-- <cmd conkeyref=""k-bppbar/cmd-$bpid""></cmd> -->" )
    Write-Host( "           <!-- <info conkeyref=""k-bppbar/info-$bpid""></info> -->" )
    Write-Host( "           <!-- <fig conkeyref=""k-bppbar/fig-$bpid""></fig> -->" )
    Write-Host( "           <step id=""step-$bpid"">" )
    if ( $menu2 -eq "" )  {
        Write-Host( "               <cmd id=""cmd-$bpid"">Go to <menucascade><uicontrol>Persona Bar</uicontrol> <uicontrol>$menu1</uicontrol></menucascade>.</cmd>" )
    }
    else  {
        Write-Host( "               <cmd id=""cmd-$bpid"">Go to <menucascade><uicontrol>Persona Bar</uicontrol> <uicontrol>$menu1</uicontrol> <uicontrol>$menu2</uicontrol></menucascade>.</cmd>" )
    }
    Write-Host( "               <info id=""info-$bpid"" outputclass=""init-hide"">" )
    Write-Host( "                   <fig id=""fig-$bpid"" outputclass=""img-scr-menu"">" )
    Write-Host( "                       <image id=""image-$bpid"" scalefit=""yes"" href=""img/$imgfn""><alt>$cascadealt</alt></image>" )
    Write-Host( "                       <pre outputclass=""olpb1-$menu1squashed-$prod$persona"">$pbicon1</pre>" )
    if ( $menu2 -ne "" )  {
        Write-Host( "                       <pre outputclass=""olpb2-$menu1squashed-$menu2squashed-$prod$persona"">$pbicon2</pre>" )
    }
    Write-Host( "                   </fig>" )
    Write-Host( "               </info>" )
    Write-Host( "           </step>" )
}


# MAIN
if ( $args.Count -gt 0 )  {
    $srccsv = $args[0]
    $prod = GetProdFromFilename $srccsv
    $persona = GetPersonaFromFilename $srccsv


    $thisscript = $MyInvocation.MyCommand.Name;
    Write-Host( "" )
    Write-Host( "" )
    Write-Host( "        <!-- ==================== $prod - $persona ==================== -->" )
    Write-Host( "        <!-- This section was generated by running: powershell -file $thisscript $srccsv > mkbp-pbar-steps.out -->" )
    Write-Host( "        <!-- START SECTION -->" )

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
        MkBlurb $prod $persona $ln.menu1 $ln.menu2

    }
}
