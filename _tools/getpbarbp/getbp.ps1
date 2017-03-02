# ============================================================
# Displays the boilerplate based on answers to questions.
# ============================================================

# GLOBAL VARIABLES -------------------------------------------

# Must be in the same folder as this powershell script.
$pbarlistfn = "pbarbplist.txt"
$tagslistfn = "tagsbplist.txt"

$stepliarr = @( "step", "li" )


# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script [step|li] persona-bar-steps-and-tags"
    $examples = @(
        "powershell -file $script [step|li] settings ""site settings"" ""site info"""
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


function AddAudience( [string] $s )  {
    if ( $s.Contains( "-host-" ) )  {
        $s = $s.Replace( "<step ", "<step audience=""adm"" " ).Replace( "<li ", "<li audience=""adm"" " )
    }
    ( "adm", "cmg", "mod" ) | foreach  {
        if ( $s.Contains( "-$_-" ) )  {
            $s = $s.Replace( "<step ", "<step audience=""$_"" " ).Replace( "<li ", "<li audience=""$_"" " )
        }
    }
    return $s
}


# MAIN -------------------------------------------------------

if ( $args.Count -gt 1 )  {
    if ( $stepliarr.Contains( $args[0] ) )  {
        $stepli = "<" + $args[0]
    }
    else {
        Usage
        return
    }
    $pbararr = @( $args[1], $args[2] ) | ? { $_ }
    $pbarstr = [string]::Join( "-", $pbararr.Replace( " ", "" ) )
    if ( $args.Count -gt 3 )  {
        $tagsarr = @( $args[1], $args[2], $args[3], $args[4] ) | ? { $_ }
        $tagsstr = [string]::Join( "-", $tagsarr.Replace( " ", "" ) )
    }
    else  {
        $tagsarr = @()
        $tagsstr = ""
    }
    Write-Host "$pbarstr"
    Write-Host "$tagsstr"

    $root = $PSCommandPath | Split-Path
    $pbarlistfn = "$root\$pbarlistfn"
    $tagslistfn = "$root\$tagslistfn"
    if (( Test-Path $pbarlistfn ) -and ( Test-Path $tagslistfn ))  {
        Write-Host ""
        Get-Content $pbarlistfn | Where { $_.ToLower().Contains( $stepli.ToLower() ) -and $_.ToLower().Contains( $pbarstr.ToLower() ) } | foreach  {
            $s = AddAudience $_
            Write-Host "    $s"
        }

        Write-Host ""
        if (( $tagsarr.Length -gt 0 ) -and ( IsValid $tagsstr ))  {
            Get-Content $tagslistfn | Where { $_.ToLower().Contains( $stepli.ToLower() ) -and $_.ToLower().Contains( $tagsstr.ToLower() ) } | foreach  {
                $s = AddAudience $_
                Write-Host "    $s"
            }
        }
    }
}

else  {
    Usage
}

# ============================================================
