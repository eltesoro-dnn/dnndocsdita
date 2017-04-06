# ============================================================
# Displays the boilerplate based on answers to questions.
# USAGE: powershell -file getbp2.ps1 menuoption
# ============================================================

# GLOBAL VARIABLES -------------------------------------------

# Must be in the same folder as this powershell script.
$pbarlistfn = "pbarbplist.txt"
$tagslistfn = "tagsbplist.txt"

$stepliarr = @( "step", "li" )


# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script [li] menus-or-tabs"
    $examples = @(
        "powershell -file $script [li] ""site info"""
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




# MAIN -------------------------------------------------------

if ( $args.Count -gt 0 )  {

    # step or bullet?
    $stepli = "<step"
    if ( $stepliarr.Contains( $args[0] ) )  {
        $stepli = "<" + $args[0]
    }

    $root = $PSCommandPath | Split-Path
    $pbarlistfn = "$root\$pbarlistfn"
    $tagslistfn = "$root\$tagslistfn"
    if ( !( Test-Path $pbarlistfn ) )  { Write-Host "File doesn't exist: $pbarlistfn"; return }
    if ( !( Test-Path $tagslistfn ) )  { Write-Host "File doesn't exist: $tagslistfn"; return }

    $tagsstr = "*" + $stepli + "*" + ([string]::Join( "*", $args)).Replace( " ", "" ).ToLower() + "-*"

    # search for it in tagslistfn
    $tags = Get-Content $tagslistfn | Where { ( $_.ToLower() -Like $tagsstr ) }

    # if found, get the matching pbar menu.
    if ( $tags.Count -gt 0 )  {
        if ( $tags.Count -eq 1 )  {
            $ln = $tags
        }
        else  {
            $ln = $tags[0]
        }
        $arr = $ln.Split( "-", [System.StringSplitOptions]::None )
        $pbarstr = "*" + $stepli + "*" + ([string]::Join( "-", $arr[4..5])).Replace( " ", "" ).ToLower() + "-*"
    }

    # if not found, just search for it in pbarlistfn
    if ( $tags.Count -eq 0 )  {
        $pbarstr = $tagsstr
    }

    $pbar = Get-Content $pbarlistfn | Where { ( $_.ToLower() -Like $pbarstr ) }

    Write-Host ""
    $pbar | foreach  { Write-Host "`t$_" }
    if ( $tags.Count -gt 0 )  {
        Write-Host ""
        $tags | foreach  { Write-Host "`t$_" }
    }
}

else  {
    Usage
}

# ============================================================
