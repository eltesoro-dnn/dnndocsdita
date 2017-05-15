# Creates the boilerplates for the Persona Bar images.
# USAGE: powershell -file mkbp-pbar-steps.ps1 pbar-???.csv mkbp-pbar-steps.out
# USAGE:
#   echo. > mkbp-pbar-steps.out
#   for /f "usebackq" %v in ( `dir pbar-*.csv /b` ) do powershell -file mkbp-pbar-steps.ps1 %v >> mkbp-pbar-steps.out
# EXAMPLE: powershell -file mkbp-pbar-steps.ps1 pbar-E90host.csv > mkbp-pbar-steps.out
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


function RefreshFile( [string] $fn )  {
    Write-Host "Recreating $fn ...."
    if ( Test-Path -Path $fn )  {
        Remove-Item  $fn  -Force  | Out-Null
    }
    New-Item  $fn  -Type file  -Force | Out-Null
}

function IsValid( [string] $s )  {
    if ( $s -eq $NULL )  {
        return $FALSE
    }
    elseif ( $s -eq "" )  {
        return $FALSE
    }
    return $TRUE
}

function WriteHeader( [string] $prod, [string] $persona, [string] $script, [string[]] $arglist )  {
    Write-Output( "`r`n" )
    Write-Output( "        <!-- ==================== $prod - $persona ==================== -->" )
    Write-Output( "        <!-- This section was generated by running: powershell -file $script $arglist -->" )
    Write-Output( "        <!-- START GENERATED SECTION -->" )
}
function WriteTail()  {
    Write-Output( "" )
    Write-Output( "        <!-- END GENERATED SECTION -->" )
}

function GetProdFromFilename( [string] $fn )  {
    $cleanfn = $fn.TrimStart( $fnprefix ).TrimEnd( $fnsuffix )
    return $cleanfn.Substring( 0, 3 )
}

function GetPersonaFromFilename( [string] $fn )  {
    $cleanfn = $fn.TrimStart( $fnprefix ).TrimEnd( $fnsuffix )
    return $cleanfn.Substring( 3, $cleanfn.Length - 3 )
}

function MkBlurb( [string] $prod, [string] $persona, [string] $menu1, [string] $menu2 )  {
    $menu1squashed = $menu1.Replace( " ", "" )
    $menu2squashed = ""
    $bpid = "pb-$persona-$menu1squashed-$prod"
    $imgfn = "scr-pbar-$persona-$menu1squashed-$prod.png"
    $cascadealt = "Persona Bar $menusep $menu1"
    if ( IsValid $menu2 )  {
        $menu2squashed = $menu2.Replace( " ", "" ).Replace( ".NET", "NET" )
        $bpid  = "pb-$persona-$menu1squashed-$menu2squashed-$prod"
        $cascadealt = "Persona Bar $menusep $menu1 $menusep $menu2"
    }

    Write-Output( "" )
    Write-Output( "" )
    Write-Output( "           <!-- <step conref=""bptext-pbar.dita#tsk-bptext-pbar/step-$bpid""><cmd/></step> -->" )
    Write-Output( "           <!-- <step conkeyref=""k-bppbar/step-$bpid""><cmd/></step> -->" )
    Write-Output( "           <!-- <li outputclass=""step""><ph outputclass=""cmd"" conkeyref=""k-bppbar/ph-$bpid""></ph></li> -->" )
    Write-Output( "           <!-- <cmd conkeyref=""k-bppbar/cmd-$bpid""></cmd> -->" )
    Write-Output( "           <!-- <info conkeyref=""k-bppbar/info-$bpid""></info> -->" )
    Write-Output( "           <!-- <fig conkeyref=""k-bppbar/fig-$bpid""></fig> -->" )
    Write-Output( "           <step id=""step-$bpid"">" )
    if ( $menu2 -eq "" )  {
        Write-Output( "               <cmd id=""cmd-$bpid""><ph id=""ph-$bpid"">Go to <menucascade><uicontrol>Persona Bar</uicontrol> <uicontrol>$menu1</uicontrol></menucascade>.</ph></cmd>" )
    }
    else  {
        Write-Output( "               <cmd id=""cmd-$bpid""><ph id=""ph-$bpid"">Go to <menucascade><uicontrol>Persona Bar</uicontrol> <uicontrol>$menu1</uicontrol> <uicontrol>$menu2</uicontrol></menucascade>.</ph></cmd>" )
    }
    Write-Output( "               <info id=""info-$bpid"" outputclass=""init-hide"">" )
    Write-Output( "                   <fig id=""fig-$bpid"" outputclass=""img-scr-menu"">" )
    Write-Output( "                       <image id=""image-$bpid"" scalefit=""yes"" href=""img/$imgfn""><alt>$cascadealt</alt></image>" )
    if (( $menu1 -ne "Profile" ) -and ( $menu1 -ne "Edit" ))  {
        Write-Output( "                       <pre outputclass=""olpb1-$menu1squashed-$prod$persona"">$pbicon1</pre>" )
        if ( $menu2 -ne "" )  {
            Write-Output( "                       <pre outputclass=""olpb2-$menu1squashed-$menu2squashed-$prod$persona"">$pbicon2</pre>" )
        }
    }
    Write-Output( "                   </fig>" )
    Write-Output( "               </info>" )
    Write-Output( "           </step>" )
}




# MAIN
if ( $args.Count -gt 1 )  {
    $infile = $args[0]
    $outfile = $args[1]
    $prod = GetProdFromFilename $infile
    $persona = GetPersonaFromFilename $infile

    # RefreshFile $outfile

    WriteHeader $prod $persona $MyInvocation.MyCommand.Name $args | Out-File -Append $outfile

    $i = $asciibase
    $j = $asciibase
	foreach ( $ln in ( Import-Csv $infile ) )  {
        if ( IsValid $ln.menu2 )  {
            $i++
            $j = $asciibase
            $pos = [char]$i
        }
        else  {
            $j++
            $pos = [char]$i + [char]$j
        }
        MkBlurb $prod $persona $ln.menu1 $ln.menu2 | Out-File -Append $outfile

    }

    WriteTail | Out-File -Append $outfile
}