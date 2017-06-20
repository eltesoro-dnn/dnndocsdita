# ============================================================
# Builds the DocCenter html files using DITA-OT.
#
# Prerequisites (You only have to do these once, not per build.):
# 1. Install Java SE JDK.
#      http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html
# 2. Download and extract DITA-OT to %DITA_HOME%.
#      http://www.dita-ot.org/download
# ============================================================


# These values are the defaults but can be overridden by environment variables of the same name but starting with "_", except where indicated
# Example: $bldroot can be overridden by the %_bldroot% evar.

# $zipoutdir
$texteditor = "%ProgramFiles%\Notepad++\notepad++.exe"  # "notepad"
$lochostdocdir = "c:\inetpub\wwwroot\docs"

$bldroot   = "v:"
$gitroot   = "w:"
$ditahome  = "C:\dita-ot"  # evar: DITA_HOME

$javajdkver = "jdk1.8.0_121"
$javahome  = $env:ProgramFiles + "\Java\" + $javajdkver  # evar: JAVA_HOME


# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script "
    $examples = @(
        "powershell -file $script _publicclasses.txt "
        )

    Write-Host "Usage: " $usage  -foregroundcolor "Yellow"
    Write-Host "Examples: "  -foregroundcolor "Yellow"
    $examples | foreach { Write-Host "    " $_  -foregroundcolor "Yellow" }
}


function Pause()  {
    Write-Host "Press any key to continue ..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") | Out-Null
}


# This is a hack because of issues with figuring out Powershell escape characters and parameters in strings.
function RunBat( [string[]] $exeandparams, [string] $runAsAdmin )  {
    $tempbat = $env:TMP + "\temp.bat"
    New-Item $tempbat  -Type file  -Force | Out-Null
    $exeandparams | foreach  {
        Write-Output $_
    } | Out-File  -FilePath $tempbat  -Encoding "Default"  -Append

    # WARNING: cmd.exe with /k causes the script to hang. Unknown reason.
    if (( $runAsAdmin ) -and (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) )  {
        Start-Process -FilePath "cmd.exe" -Verb runAs -ArgumentList "/c $tempbat"
    }
    else  {
        & "cmd.exe" /c $tempbat
    }
}


# Gets the original drive of a mapped drive.
function GetRemoteDrive( [string] $mapdrv )  {
    $mapdrv = $mapdrv.ToUpper()
    $logicalDisk = Get-WMIObject Win32_LogicalDisk -filter "DriveType = 4 AND DeviceID = '$mapdrv'"
    return ( $logicalDisk.ProviderName )
}


# Gets the line in the resource file (js|css) that contains the parameters to add to the URL calling the resource.
function GetVersionURLParams( [string] $fn )  {
    $prefixsearch = " | ?ver="
    $prefixtrim   = " | "
    Get-Content $fn | Where { $_.StartsWith( $prefixsearch ) } | foreach  {
        $x = $_.Replace( $prefixtrim, "" )
        return ( $x )
    }
}


function ChkThenMkDir( [string] $folder )  {
    if ( -not( Test-Path $folder ) )  {
        New-Item  $folder  -Type directory | Out-Null
    }
}

function ChkThenRmDir( [string] $folder )  {
    if ( Test-Path -Path $folder )  {
        Remove-Item $folder -Recurse -Force | Out-Null
    }

    $confirmation = 'r'
    while (( Test-Path -Path $folder ) -and ( $confirmation -eq 'r' ))  {
        $confirmation = Read-Host "Unable to clear $_. Proceed anyway [p], retry [r], or cancel [x]?"
        switch ( $confirmation ) {
            'r' { Remove-Item $folder -Recurse -Force | Out-Null }
            'x' { throw "Cancelled by user." }
        }
    }
}


# $opts: /s = subdirectories
function RobocopyBasic( [string] $src, [string] $tgt, [string] $opts, [string] $role )  {
    Write-Host "Copying from $src to $tgt with options $opts ...."
    $cmdarr = @( "@robocopy " + $src + " " + $tgt + " /mt /log+:" + $cpylog + " " + $opts )
    RunBat $cmdarr $role | Out-Null
}
function RobocopyIncludeArray( [string] $src, [string] $tgt, [string] $includearr, [string] $opts )  {
    Write-Host "Copying from $src to $tgt, including $includearr, with options $opts ...."
    $includearr.Split( "," ) | foreach  {
        $cmdarr = @( "@robocopy " + $src + " " + $tgt + " " + $_ + " /mt /log+:" + $cpylog + " " + $opts )
        RunBat $cmdarr | Out-Null
    }
}
function RobocopyExcludeFiles( [string] $src, [string] $tgt, [string] $excludefiles, [string] $opts )  {
    Write-Host "Copying from $src to $tgt, excluding $excludefiles, with options $opts ...."
    $cmdarr = @( "@robocopy " + $src + " " + $tgt + " /xf " + $excludefiles + " /mt /log+:" + $cpylog + " " + $opts )
    RunBat $cmdarr | Out-Null
}
function RobocopyExcludeDirs( [string] $src, [string] $tgt, [string] $excludedirs, [string] $opts )  {
    Write-Host "Copying from $src to $tgt, excluding $excludedirs, with options $opts ...."
    $cmdarr = @( "@robocopy " + $src + " " + $tgt + " /xd " + $excludedirs + " /mt /log+:" + $cpylog + " " + $opts )
    RunBat $cmdarr | Out-Null
}


function RefreshLog()  {
    Write-Host "Recreating $logfile ...."

    if ( -not( Test-Path -Path $logdir ) )  {
        New-Item  $logdir  -Type directory  -Force | Out-Null
    }

    ( $bldlog, $cpylog ) | foreach  {
        if ( Test-Path -Path $_ )  {
            Remove-Item  $_  -Force  | Out-Null
        }
        New-Item  $_  -Type file  -Force | Out-Null
    }
}


function RefreshFolders()  {
    Write-Host "Recreating build folder and output folder ...."

    ( $blddir, $outdir ) | foreach {
        ChkThenRmDir $_
        if ( -not( Test-Path -Path $_ ) )  {
            New-Item $_  -Type directory  -Force | Out-Null
        }
    }
}


function TestPathOrThrow( [string] $path )  {
    try  {
       Test-Path -Path $path
    }
    catch [Exception]  {
        Write-Host $_.Exception.GetType().FullName  -foregroundcolor "Red"
        Write-Host $_.Exception.Message  -foregroundcolor "Red"
        throw( "Exception" )
    }
}

function RefreshDITAOT()  {
    Write-Host "Refreshing the DITA-OT files ...."

    ChkThenRmDir $ditahome

    $tgtdir = $ditahome + "\.."
    Expand-Archive -Path $ditaotzip -DestinationPath $tgtdir -Force
    TestPathOrThrow $tgtdir\dita-ot-$ditaotver

    Rename-Item "$tgtdir\dita-ot-$ditaotver" "$ditahome"

    # DNN-specific files.
    ( "$ditahome\plugins\org.dnn.dc" ) | foreach  {
        ChkThenRmDir $_
        if ( -not( Test-Path -Path $_ ) )  {
            New-Item $_  -Type directory  -Force | Out-Null
            RobocopyBasic "$gitdir\_build\org.dnn.dc" $_ "/s"
        }
    }

    Write-Host "Integrating our own DITA-OT plugin ...."
    Set-Location  -Path $ditahome
    RunBat @( "ant -f integrator.xml  strict" )
}


# Copies time-sensitive versions of files in the build folder.
# The temporary version of the file must be named as follows:
#   PRE_YYYYMMDD_original-filename.dita  - The temporary file will be used before the specified date.
#   POST_YYYYMMDD_original-filename.dita - The temporary file will be used after the specified date.
function CopyTimeSensitiveFiles( [string] $src, [string] $tgt, [string] $filter )  {
    Write-Host "Copying time-sensitive versions ...."

    foreach ( $prefix in @( "PRE", "POST" ) )  {
        $inc = $prefix + "_*" + $filter
        Get-ChildItem -Path $src\.. -Include $inc -Recurse | foreach {
            $fnarr = ($_.Name).Split( "_", [System.StringSplitOptions]::RemoveEmptyEntries )

            $now = [int] ( Get-Date -Format "yyyyMMdd" )
            $yyyyMMdd = [int] ( $fnarr[1] )

            $isActive = $false;
            switch ( $prefix ) {
                "PRE"  { if ( $now -lt $yyyyMMdd )  { $isActive = $true } }
                "POST" { if ( $now -gt $yyyyMMdd )  { $isActive = $true } }
            }
            if ( $isActive ) {
                $fn = $_.FullName
                $path = $_.DirectoryName
                Write-Host "  $fn"
                if ( $tgt -ne $NULL )  {
                    $path.Replace( $src, $tgt )
                }
                $cleanfn = $fnarr[2]
                Copy-Item  -Path $fn -Destination "$path\$cleanfn" -Force
            }
        }
    }
}


# This is a hack because the css references require changes in the DITA-OT XSLT.
# The js references are easy to update in dnn-head and dnn-footer, but added here anyway for consistency.
function AddVersioning( [string] $tgtdir, [string] $fnfilter )  {
    Write-Host "Adding versioning for .css and .js in $tgtdir\$fnfilter ...."

    $rep1 = GetVersionURLParams "$thmdir\dnndocsltr.css"
    $rep2 = GetVersionURLParams "$thmdir\headscripts.js"
    $rep3 = GetVersionURLParams "$thmdir\scripts.js"

    # Retrieve every file that meets the $fnfilter.
    $arr  = Get-ChildItem -Path $tgtdir   -Include $fnfilter -Recurse

    Write-Host "dnndocsltr.css$rep1"
    Write-Host "headscripts.js$rep2"
    Write-Host "scripts.js$rep3"
    Write-Host "Updating " $arr.Length " files ...."
    foreach ( $fn in $arr )  {
        ( Get-Content $fn ) | foreach  {
            $_  -replace "/dnndocsltr.css", "/dnndocsltr.css$rep1"`
                -replace "/headscripts.js", "/headscripts.js$rep2"`
                -replace "/scripts.js"    , "/scripts.js$rep3"
        } | Set-Content $fn
    }
}


function CopyBldFolders()  {
    Write-Host "Copying files required by the build ...."

    Write-Host "Copying from $gitdir\_content to $blddir"
    RobocopyIncludeArray  "$gitdir\_content"                 "$blddir"                 "*.html,*.dita*,*.png,*.gif,*.svg" "/s"
    RobocopyBasic         "$gitdir\_content\common\samples"  "$blddir\common\samples"                                     "/s"
    RobocopyIncludeArray  "$gitdir\_themes\dnn"              "$blddir\_themes\dnn"     "dnn*.css"

    CopyTimeSensitiveFiles $blddir $blddir
    CopyTimeSensitiveFiles $blddir $blddir "*.html"

    foreach ( $subbld in $subbldarr )  {
        if ( $subbld -ne "api" )  {
            RobocopyIncludeArray "$blddir\common" "$blddir\$subbld" "*.dita*" "/s"
        }
    }
}


function BuildDITADocs()  {
    Write-Host "Building ...."

    Copy-Item  -Path $gitdir\_build\dnn_build.xml  -Destination $ditahome  -Force | Out-Null
    Copy-Item  -Path $gitdir\_build\*.ditaval      -Destination $ditahome  -Force | Out-Null

    # Must start at $ditahome
    Set-Location -Path $ditahome
    $batcontents = "ant " + $transtype + " -f " + $ditahome + "\dnn_build.xml -l " + $bldlog
    RunBat @( $batcontents )
}


function AssembleOutput()  {
    Write-Host "Copying additional required files to the output ...."

    Copy-Item  -Path "$blddir\index.html"          -Destination "$outdir"  -Force | Out-Null
    # Copy-Item  -Path "$gitdir\_content\index.html"          -Destination "$outdir"  -Force | Out-Null
    # CopyTimeSensitiveFiles "$gitdir\_content" $outdir "index.html"

    Copy-Item  -Path "$blddir\searchresults.html"  -Destination "$outdir"  -Force | Out-Null
    # Copy-Item  -Path "$gitdir\_content\searchresults.html"  -Destination "$outdir"  -Force | Out-Null
    # CopyTimeSensitiveFiles "$gitdir\_content" $outdir "searchresults.html"

    RobocopyBasic         "$gitdir\_content\common\samples"   "$outdir\common\samples"                                          "/s"
    RobocopyIncludeArray  "$gitdir\_themes\dnn"               "$outdir\_theme"          "*.jpg,*.png,*.gif,*.svg,26d3f6*,*.js"

    #Copy only the images that are actually used.
    #old: RobocopyIncludeArray  "$gitdir\_content\common\img"       "$outdir\common\img"      "*.jpg,*.png,*.gif,*.svg"
    $imgfiles = Get-ChildItem -Path $outdir\*.html -Recurse | Select-String -Pattern "(scr-[a-zA-Z0-9_-]+.png)|(scr-[a-zA-Z0-9_-]+.gif)|(scr-[a-zA-Z0-9_-]+.svg)|(gra-[a-zA-Z0-9_-]+.png)|(gra-[a-zA-Z0-9_-]+.gif)|(gra-[a-zA-Z0-9_-]+.svg)|(ico-[a-zA-Z0-9_-]+.png)|(ico-[a-zA-Z0-9_-]+.gif)|(ico-[a-zA-Z0-9_-]+.svg)" -AllMatches | foreach { $_ -match "img/(?<content>.*)"" alt" | Out-Null; $matches['content'] } | Sort-Object | Get-Unique
    foreach ( $img in $imgfiles )  {
        Copy-Item  -Path "$gitdir\_content\common\img\$img"  -Destination "$outdir\common\img"  -Force | Out-Null
    }

    # The following is a hack.
    Copy-Item  -Path $outdir\developers\creating-modules\index.html  -Destination $outdir\developers\extensions  -Force
    Copy-Item  -Path $outdir\designers\creating-themes\index.html    -Destination $outdir\designers\extensions   -Force

    Write-Host "Deleting files we don't need ...."
    if ( Test-Path $outdir\toc.html          )  { Remove-Item $outdir\toc.html -Force | Out-Null }
    if ( Test-Path $outdir\common\glossary\* )  { Remove-Item $outdir\common\glossary -Recurse -Force | Out-Null }
    RunBat @( "del $outdir\bptext*.html /s /q" )  # BUGBUG: This is a hack. Haven't figured out why the build created these files.

    # Write-Host "Adding versioning to .css and .js calls in html files ...."
    AddVersioning $outdir "*.html"

    Write-Host "Creating the web.config ...."
    & $gitdir\_build\urlmap\urlmap.ps1 $gitdir\_build\urlmap\DC-URLmapping.csv $outdir $outdir\web.config

    Write-Host "Creating an aboutbld.html file ...."
    $today = Get-Date  -Format "yyyyMMdd"
    Write-Output "DocCenter v1.3 Build $today" | Set-Content $outdir\aboutbld.html
}


function Publish2Localhost()  {
    # Replace the mapped build drive with the WMI ProviderName.
    if ( $unmappedbldroot )  {
        $srcdir = $outdir.Replace( $bldroot, $unmappedbldroot )
    }
    else  {
        $srcdir = $outdir
    }

    Write-Host "Copying built files from $srcdir to $lochostdocdir ...."
    RunBat @( "@echo off",
              "for /f ""usebackq"" %%v in (``dir $lochostdocdir /a:d /b``)  do rd /s /q $lochostdocdir\%%v",
              "del /q $lochostdocdir\*",
              "if not exist $lochostdocdir\*  md $lochostdocdir",
              "robocopy $srcdir $lochostdocdir /s /mt /log+:$cpylog",
              "if exist $lochostdocdir\web.config  del $lochostdocdir\web.config" ) "runasadmin"

    # Write-Host "TO DO: Manually copy the files from $srcdir to $lochostdocdir." -foregroundcolor "Yellow"
    # Explorer $srcdir
    Explorer $lochostdocdir
}


function ZipOutput()  {
    $now = Get-Date -Format "yyyyMMddHHmm"
    $tgtzip = "$zipdir\$now-$transtype.zip"

    Write-Host "Zipping to $tgtzip...."
    if ( Test-Path $tgtzip )  { Remove-Item $tgtzip -Force }
    Compress-Archive  -Path $outdir  -DestinationPath $tgtzip
    Copy-Item  -Path $tgtzip  -Destination $zipoutdir  -Force
}


# MAIN -------------------------------------------------------


    Write-Host "Setting environment variables ...."

    # Array of subcenters to build.
    $subbldarr = "administrators", "developers", "designers", "content-managers", "community-managers", "api"

    # Array of custom css and jscript files.
    $cssjsarr = ( "dnndocsltr.css", "headscripts.js", "scripts.js" )

    # Switching to a different DITA-OT version can cause build errors.
    $ditaotver = "2.2.2"
    $ditaotzip = $gitroot + "\_build\dita-ot-$ditaotver.zip"

    # File extension of the web pages generated by the build. Can also be .shtml.
    # If you change $outext, remember to replace the links in the root index.html.
    $outext = ".html"
    $env:_outext = $outext

    # Target format for the build.
    $transtype = "html5"

    # For zipoutdir, the evar has higher priority.
    if ( $env:_zipoutdir     -eq $NULL )  { $zipoutdir = $NULL }  else { $zipoutdir = $env:_zipoutdir }

    # Override basic variables with corresponding evars if defined. If the evar is not defined, set it to the PS var.
    if ( $env:_texteditor    -eq $NULL )  { $env:_texteditor    = $texteditor    }  else { $texteditor    = $env:_texteditor    }
    if ( $env:_lochostdocdir -eq $NULL )  { $env:_lochostdocdir = $lochostdocdir }  else { $lochostdocdir = $env:_lochostdocdir }
    if ( $env:_bldroot       -eq $NULL )  { $env:_bldroot       = $bldroot       }  else { $bldroot       = $env:_bldroot       }
    if ( $env:_gitroot       -eq $NULL )  { $env:_gitroot       = $gitroot       }  else { $gitroot       = $env:_gitroot       }
    if ( $env:_javajdkver    -eq $NULL )  { $env:_javajdkver    = $javajdkver    }  else { $javajdkver    = $env:_javajdkver    }
    if ( $env:_ditaotver     -eq $NULL )  { $env:_ditaotver     = $ditaotver     }  else { $ditaotver     = $env:_ditaotver     }
    if ( $env:_ditaotzip     -eq $NULL )  { $env:_ditaotzip     = $ditaotzip     }  else { $ditaotzip     = $env:_ditaotzip     }

    # Generated variables (defaults).
    $blddir = $bldroot + "\bld\" + $transtype
    $gitdir = $gitroot + "\."
    $thmdir = $gitroot + "\_themes\dnn"
    $outdir = $bldroot + "\output\" + $transtype
    $zipdir = $bldroot + "\output"
    $cssfile = $thmdir + "\dnndocsltr.css"

    # Logs must be in unmapped build root dir so it can be passed to a cmd.exe with no drive mappings.
    $unmappedbldroot = GetRemoteDrive( $bldroot )
    $logdir = $unmappedbldroot + "\logs"
    $bldlog = $logdir  + "\bld-" + $transtype + ".log"
    $cpylog = $logdir  + "\cpy-" + $transtype + ".log"

    # Override generated variables with corresponding evars if defined.
    if ( $env:_blddir  -eq $NULL )  { $env:_blddir  = $blddir }  else { $blddir  = $env:_blddir }
    if ( $env:_gitdir  -eq $NULL )  { $env:_gitdir  = $gitdir }  else { $gitdir  = $env:_gitdir }
    if ( $env:_thmdir  -eq $NULL )  { $env:_thmdir  = $thmdir }  else { $thmdir  = $env:_thmdir }
    if ( $env:_outdir  -eq $NULL )  { $env:_outdir  = $outdir }  else { $outdir  = $env:_outdir }
    if ( $env:_zipdir  -eq $NULL )  { $env:_zipdir  = $zipdir }  else { $zipdir  = $env:_zipdir }
    if ( $env:_logdir  -eq $NULL )  { $env:_logdir  = $logdir }  else { $logdir  = $env:_logdir }
    if ( $env:_bldlog  -eq $NULL )  { $env:_bldlog  = $bldlog }  else { $bldlog  = $env:_bldlog }
    if ( $env:_cpylog  -eq $NULL )  { $env:_cpylog  = $bldlog }  else { $bldlog  = $env:_cpylog }
    if ( $env:_cssfile -eq $NULL )  { $env:_cssfile = $bldlog }  else { $bldlog  = $env:_cssfile }


    if ( $env:DITA_HOME -eq $NULL )  { $env:DITA_HOME = $ditahome }  else { $ditahome = $env:DITA_HOME }
    if ( $env:ANT_HOME  -eq $NULL )  { $env:ANT_HOME  = $ditahome }  else { $anthome = $env:DITA_HOME  }
    $antexe  = $anthome + "\bin\ant.bat"

    if ( $env:JAVA_HOME -eq $NULL )  { $env:JAVA_HOME = $javahome }  else { $javahome = $env:JAVA_HOME }
    $javaexe = $javahome + "\bin\java.exe"
    if ( Test-Path $javaexe )     { $env:JAVACMD = $javaexe    }  else { $env:JAVACMD = "java.exe"  }

    $env:PATH = $javahome + "\bin;" + $ditahome + "\bin;" + $anthome + "\tools\ant\bin;" + $env:PATH

    # from $ditahome\resources\env.bat
    $addclasspath = "$ditahome\plugins\org.dita.pdf2\lib\fo.jar;$ditahome\plugins\org.dita.pdf2.axf\lib\axf.jar;$ditahome\plugins\org.dita.pdf2.xep\lib\xep.jar"
    if ( $env:_logfile -eq $NULL )  {
        $env:CLASSPATH = $addclasspath
    }
    else  {
        $env:CLASSPATH = $env:CLASSPATH + ";" + $addclasspath
    }

    Write-Host "    blddir:   $blddir  "
    Write-Host "    gitdir:   $gitdir  "
    Write-Host "    outdir:   $outdir  "
    Write-Host "    logdir:   $logdir  "
    Write-Host "    logfile:  $bldlog  "
    Write-Host "    ditahome: $ditahome"
    Write-Host "    anthome:  $anthome "
    Write-Host "    antexe:   $antexe  "
    Write-Host "    javahome: $javahome"
    Write-Host "    CLASSPATH: $env:CLASSPATH"

    # ----------


    RefreshLog
    RefreshFolders
    RefreshDITAOT
    CopyBldFolders
    BuildDITADocs

    $failed = 0
    $subbldarr | foreach  {
        if ( -not( Test-Path -Path $outdir\$_\* ) )  {
            Write-Host "FATAL: Build failed for the subcenter $_." -foregroundcolor "Red"
            $failed += 1
        }
    }
    if ( $failed -gt 0 )  {
        & "cmd.exe" /c $texteditor $bldlog
    }
    else  {
       AssembleOutput
       Publish2Localhost
       if ( $zipoutdir )  { ZipOutput }
    }


# ============================================================

# TODO: Write-Host error/warn lines in the %_logfile%.
# TODO: Copy to staging server via FTP.

# ============================================================
