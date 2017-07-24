# ============================================================
# Creates the content items for the Persona Bar options.
#
# NOTES:
# * The csv for pbar contains: menu1,menu2,left1,top1,left2,top2,hori,vert,left1pc,top1pc,left2pc,top2pc
# * The csv for pbtabs contains: menu1,menu2,tab1,tab2,host,adm,cmg,mod,imgprod,notes
# ============================================================


# GLOBAL VARIABLES -------------------------------------------

$indent = "            "


# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script $csv $out"

    $examples = @(
        "powershell -file $script pbar-???.csv permutations.out"
        )

    Write-Host "Usage: " $usage
    Write-Host "Examples: "
    $examples | foreach { Write-Host "    " $_ }
}

function Pause()  {
    Write-Host "Press any key to continue ..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") | Out-Null
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
function IsNotValid( [string] $s )  {
    return !( IsValid $s )
}


# Expected format for $fn: prefix-X99persona.ext
# $format can contain the following components:
#  %p% = path only
#  %f% = filename without extension
#  %x% = file extension
#  %prefix% = pbar or pbtabs (or the first element before the first "-")
#  %X99% = product
#  %persona% = the remaining letters after the product
#  %bptype% = type of boilerplate, plural; e.g., steps, tasks, images
function GetFnComponent( [string] $fn, [string] $format )  {
    $arr = $fn.Split( ".", [System.StringSplitOptions]::None ).Split( "\", [System.StringSplitOptions]::None )
    $p   = [string]::Join( "\", $arr[0..-3] )
    $f   = $arr[-2]
    $x   = $arr[-1]
    $arr = $f.Split( "-", [System.StringSplitOptions]::None )

    $format = $format.Replace( "%p%", $p )
    $format = $format.Replace( "%f%", $f )
    $format = $format.Replace( "%x%", $x )
    $format = $format.Replace( "%prefix%", $arr[0] )
    switch ( $arr[0] )  {
        "jobs"  {
            $format = $format.Replace( "%bptype%", $arr[1] )
        }
        default  {
            $format = $format.Replace( "%X99%", $arr[1].Substring( 0, 3 ) )
            $format = $format.Replace( "%persona%", $arr[1].Substring( 3, $arr[1].Length - 3 ) )
        }
    }

    return $format
}

function FormatArray( [string[]] $arr )  {
    $s = "[ """
    $s += [string]::Join( """, """, $arr )
    $s += """ ]"
    return $s
}

function BldJson( [string] $bptype, [string] $menutype, [string] $persona, [PSObject] $ln )  {
    $option = "$bptype-$menutype"
    $memberarr = @()
    switch( $option )  {
        "images-pbar"   {  $memberarr = ( "_persona_", "_dashed_", "_menualt_", "_sig_" )  }
        "images-pbtabs" {  $memberarr = ( "_persona_", "_dashed_", "_menualt_", "_sig_" )  }
        "steps-pbar"    {  $memberarr = ( "_persona_", "_dashed_", "_menucasc_", "_id-image_" )  }
        "steps-pbtabs"  {  $memberarr = ( "_persona_", "_dashed_", "_tab1cmd_", "_tab2cmd_", "_id-image_" )  }
        default         {  $memberarr = @(); Write-Host "WARNING: Menu type is not recognized: $menutype"  }
    }

    $menu1 = $ln.menu1
    $menu2 = $ln.menu2
    $tab1  = $ln.tab1
    $tab2  = $ln.tab2
    $menuarr = @( $menu1 )
    if ( IsValid $menu2 )  { $menuarr += $menu2 }
    if ( IsValid $tab1 )   { $menuarr += $tab1 }
    if ( IsValid $tab2 )   { $menuarr += $tab2 }

    $dashed = [string]::Join( "-", $menuarr )
    $dashed = $dashed.Replace( " ", "" ).Replace( "/", "" ).ToLower()


    $newobj = [PSCustomObject]@{}
    $memberarr | foreach {
        switch ( $_ )  {
            "_persona_"   { $val = "$persona" }
            "_dashed_"    { $val = $menuarr }
            "_menualt_"   { $val = $menuarr }
            "_menucasc_"  { $val = $menuarr }
            "_tab1cmd_"   { $val = ""; if ( IsValid $tab1 ) { $val = "Go to the <uicontrol>$tab1</uicontrol> tab" } }
            "_tab2cmd_"   { $val = ""; if ( IsValid $tab2 ) { $val = ", and then the <uicontrol>$tab2</uicontrol> subtab" } }
            "_id-image_"  {
                switch( $option )  {
                    "steps-pbar"    { $val = "scr-pbar-$persona-$dashed-E91" }
                    "steps-pbtabs"  { $val = "scr-pbtabs-$persona-$dashed-E91" }
                    default         { $val = "" }
                }
            }
            "_sig_"       { $val = "" }
            default       { $val = "" }
        }
        $newObj | Add-Member -Name "$_" -Type NoteProperty -Value $val
    }

    $newjson = $newobj | ConvertTo-Json -Depth 10

    # Prettify
    $newjson = "$indent$newjson," -replace "`r`n                \ +", " " -replace "`r`n", "`r`n$indent"

    return $newjson
}



# MAIN -------------------------------------------------------

if ( $args.Count -gt 1 )  {
    $csv = $args[0]
    $out = $args[1]

    $menutype = GetFnComponent $csv "%prefix%"      # pbar, pbtabs
    $persona  = GetFnComponent $csv "%persona%"     # host, adm, cmg, mod
    $bptype   = GetFnComponent $out "%bptype%"      # images, steps, tasks, etc.

    New-Item -Name $out -ItemType "file" -Force | Out-Null

    foreach ( $ln in ( Import-Csv $csv ) )  {
        switch ( $menutype )  {
            "pbar" {
                BldJson $bptype $menutype $persona $ln | Out-File $out -Encoding Default -Append
            }
            "pbtabs"  {
                if ( IsValid $ln.tab1 )  {
                    $personaarr = @()
                    ( "host", "adm", "cmg", "mod" ) | foreach  {
                        if ( IsValid $ln.$_ )  {  $personaarr += $ln.$_  }
                    }
                    $personaarr = $personaarr | Sort-Object | Get-Unique
                    $personaarr | foreach  {
                        BldJson $bptype $menutype $_ $ln | Out-File $out -Encoding Default -Append
                    }
                }
            }
            default  {
                Write-Host "ERROR: Invalid menu type: $menutype"
            }
        }
    }
}
else  {
    Usage
}


# ============================================================
