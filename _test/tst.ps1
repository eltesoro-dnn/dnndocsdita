# ============================================================
# Runs tests on the doc build.
#
# NOTES:
# * Some tests cannot be done on the localhost.
# ============================================================


$transtype = "html5"
$subbldarr = "administrators", "developers", "designers", "content-managers", "community-managers"

$bldroot   = "v:"
$gitroot   = "w:"

$outdir = $bldroot + "\output\" + $transtype
$logdir = $bldroot + "\logs"

$gitdir = $gitroot + "\."
$ctndir = $gitroot + "\_content"
$imgdir = $gitroot + "\_content\common\img"
$tstdir = $gitroot + "\_test"

$tstlog    = $logdir + "\tst-" + $transtype + ".log"
$currfiles = $logdir + "\currfiles.txt"

$expfile   = $tstdir + "\expectedfiles.txt"

$staging = "http://doccenterqa.azurewebsites.net/docs"

# set _tempfile=%_logdir%\temp.txt
# set _urlmap=W:\_build\urlmap\urlmap.txt


function IsValid( [string] $s )  {
    if ( $s -eq $NULL )  {
        return $FALSE
    }
    elseif ( $s -eq "" )  {
        return $FALSE
    }
    return $TRUE
}


function WriteHeader( [string] $msg )  {
    Write-Host $msg

    Write-Output "`r`n--------------------------------------------------"
    Write-Output $msg
}


function RefreshFile( [string] $fn )  {
    if ( Test-Path $fn )  {
        Remove-Item $fn  -Force | Out-Null
    }
    New-Item $fn  -Type file  -Force | Out-Null
}


function RunBat( [string] $exeandparams )  {
    $tempbat = $blddir + "\temp.bat"
    New-Item $tempbat  -Type file  -Force  -Value $exeandparams | Out-Null
    & "cmd.exe" /c $tempbat
}


function TestUrl( $url )
{
    $error.clear()
    try  {
        $test = Invoke-WebRequest -method head -uri $url
    }
    catch  {
        $errcode = $_.Exception.Response.StatusCode.Value__
        Write-Output( "*** Error $errcode $url" )
    }
    if ( !$error )  {
        # $code = $test.StatusCode
        $desc = $test.StatusDescription
        return "$desc $url"
    }
}


function T001()  {
    WriteHeader "Checking that all expected files are in the output folder."
    Get-Content $expfile | foreach  {
        if (( $_ ) -and !(Test-Path $outdir\$_ ))  {
            Write-Output "Missing output: $_"
        }
    }
}


function T002()  {
    WriteHeader "Checking new files."
    RefreshFile $currfiles

    $index = $outdir.Length + 1
    Get-ChildItem -Path $outdir -File -Recurse | foreach  {
        ($_.FullName).Substring( $index ) | Out-File -Append $currfiles
    }
    Write-Output "foo.txt" | Out-File -Append $currfiles
    & "cmd.exe" /c windiff $expfile $currfiles

    $confirm = Read-Host "Copy the new list? [y/n]"
    if ($confirm -eq 'y') {
        Copy-Item  -Path $currfiles  -Destination $expfile  -Force
    }
}


# Source: get-mentioned-images.ps1
function T003()  {
    WriteHeader "Verifying that mentioned images exist."
    Write-Output "Missing image files:"

    # $imgfiles = Get-ChildItem -Path $ctndir\*.dita -Recurse | Select-String -Pattern "(scr[a-zA-Z0-9_-]+.png)|(scr[a-zA-Z0-9_-]+.gif)|(scr[a-zA-Z0-9_-]+.svg)" -AllMatches | foreach { $_ -match "img/(?<content>.*)"" alt" | Out-Null; $matches['content'] }

    $imgfiles = Get-ChildItem -Path $outdir\*.html -Recurse | Select-String -Pattern "(scr[a-zA-Z0-9_-]+.png)|(scr[a-zA-Z0-9_-]+.gif)|(scr[a-zA-Z0-9_-]+.svg)" -AllMatches | foreach { $_ -match "img/(?<content>.*)"" alt" | Out-Null; $matches['content'] }

    foreach ( $img in $imgfiles )  {
        if (!( Test-Path $imgdir\$img )) {
            Write-Output "`t$img"
        }
    }
}


function T004()  {
    WriteHeader "In Dr. Link Check, enter $staging and click Start."
    Start http://www.drlinkcheck.com/
}


# Source: testwinconfig.ps1
function T005()  {
    WriteHeader "Testing win.config."

    $UrlPrefix = $staging
    $legacycsv = $gitdir + "\_build\urlmap\DC-URLmapping.csv"
    $exceptnfile = $tstdir + "\indexfileexceptions.txt"

    $exceptnarr = Get-Content $exceptnfile

    # Test the old paths in $legacycsv.
    Import-csv $legacycsv | foreach  {
        if ( IsValid $_.example ) {
            $url = $UrlPrefix + "/" + $_.example
        }
        else {
            $url = $UrlPrefix + "/" + $_.old
        }

        if ( $exceptnarr -contains $url )  {
            Write-Output( "OK Exempted from testing: " + $url )
        }
        else  {
            testUrl( $url )
        }
    }

    # Test the persona subdirectories in $outdir
    $personalist = @( "administrators", "content-managers", "developers", "designers", "community-managers" )
    foreach ( $persona in $personalist )  {
        $persdir = $outdir + "/" + $persona
        foreach ( $fn in ( Get-ChildItem -path $persdir -recurse | Where-Object {$_.PSIsContainer -eq $True} ) )  {
            $fnclean = $persona + "/" + $fn.FullName.SubString( $persdir.Length + 1 ).Replace( "\", "/" )
            if ( -not ( $exceptnarr -contains $fnclean ) )  {
                $url = $UrlPrefix + "/" + $fnclean
                testUrl( $url )
                testUrl( $url + "/"  )
            }
            else  {
                Write-Output( "OK Exempted from testing: " + $fnclean )
            }
        }
    }
}



# MAIN -------------------------------------------------------

# Cancel if the output folder doesn't exist.
if ( !( Test-Path $outdir ) )  {
    Write-Error "ERROR: The output folder doesn't exist. $outdir"
    return
}

# Create the log directory if it doesn't exist.
if ( !( Test-Path $logdir ) )  { New-Item $logdir  -Type directory  -Force | Out-Null }

# Rebuild the test log.
RefreshFile $tstlog
Get-Date | Out-File $tstlog


T001 | Out-File -Append $tstlog
T002 | Out-File -Append $tstlog
T003 | Out-File -Append $tstlog
T004 | Out-File -Append $tstlog
T005 | Out-File -Append $tstlog

& "cmd.exe" /c npp.bat $tstlog


# ============================================================
