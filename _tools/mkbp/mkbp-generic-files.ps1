# Creates the boilerplates for steps.
# USAGE: powershell -file mkbp-generic-files.ps1 rolesfiles.in bptext-rolessteps prolog.txt presteps.txt .\out
#
# WARNINGS:
#   * For overlays on the image:
#       - Do NOT use "align=". It creates a <div> around the image.
#       - Do NOT use "placement="break"". It adds <br/> before and after the image.


function GetConrefType  {
    param( [string] $conref )
    $refarr = $conref.Split( "-", [System.StringSplitOptions]::None )
    return $refarr[0]
}

function MkHeader  {
    param( [string] $title, [string] $nav, [string] $prologfn, [string] $prestepsfn, [string] $tgtdir )

    $navdashed = ($nav.ToLower()).Replace( " ", "-" )
    Write-Output "<?xml version=""1.0"" encoding=""utf-8"" standalone=""no""?>"
    Write-Output "<!DOCTYPE task PUBLIC ""-//OASIS//DTD DITA General Task//EN"" ""http://docs.oasis-open.org/dita/v1.2/os/dtd1.2/technicalContent/dtd/generaltask.dtd"">"
    Write-Output "<task xml:lang=""en"" id=""tsk-$navdashed"">"
    Write-Output ""
    Write-Output "    <title>$title</title>"
    if ( $nav -ne "" )  {
        Write-Output "    <titlealts>"
        Write-Output "        <navtitle>$nav</navtitle>"
        Write-Output "    </titlealts>"
    }
    Write-Output  ""
    Write-Output  ""
    Get-Content $prologfn
    Write-Output ""
    Write-Output ""
    Write-Output "    <taskbody>"
    Write-Output ""
    Get-Content $prestepsfn
    Write-Output ""
}

function MkNote  {
    param( [string] $note, [string] $bp )
    $reftype = GetConrefType $note
    if ( $reftype -eq "note" )  {
        Write-Output "        <section><note conref=""$bp.dita#tsk-$bp/$note""></note></section>"
    }
    elseif ( $reftype -eq "ph" ) {
        Write-Output "        <section><note><ph conref=""$bp.dita#tsk-$bp/$note""></ph></note></section>"
    }
    Write-Output ""
}

function MkStepPBar  {
    param( [string] $name, [string[]] $arr )

    foreach( $role in $arr )  {
        Write-Output "            <step audience=""$role"" conkeyref=""k-bppbar/step-pb-$role-$name-E90""><cmd/></step>"
    }
}

function MkStepBPLocal  {
    param( [string] $name, [string] $bp )
    Write-Output "            <step conref=""$bp.dita#tsk-$bp/$name""><cmd/></step>"
}

function MkStepLiteral  {
    param( [string] $cmd )
    Write-Output "            <step><cmd>$cmd</cmd></step>"
}

function MkResult  {
    param( [string] $text )
    Write-Output "        <result>$text</result>"
    Write-Output ""
}

function StartSteps  {
    Write-Output "        <steps>"
}

function EndSteps  {
    Write-Output "        </steps>"
    Write-Output ""
}

function EndBody  {
    Write-Output "    </taskbody>"
    Write-Output ""
    Write-Output "</task>"
    Write-Output ""
}


# MAIN
if ( $args.Count -gt 4 )  {
    $srcfn = $args[0]
    $bpfnbase = $args[1]
    $prologfn = $args[2]
    $prestepsfn = $args[3]
    $tgtdir = $args[4]
    $tgtfile = $tgtdir + "\foo.dita"
    $nav = ""
    $openbodytag = $FALSE

    foreach ( $ln in ( Get-Content $srcfn ) )  {

        $lnstr = $ln.ToString()

        if ( $ln -eq "" )  {
            if ( $openbodytag )  {
                EndBody [ref] $openbodytag | Out-File $tgtfile -Append -Encoding DEFAULT
                $openbodytag = $FALSE
            }
        }
        else  {

            if ( $lnstr.StartsWith( "nav: " ) ) {
                $nav = $lnstr.Substring( "nav: ".Length )
                $tgtfile = $tgtdir + "\" + ($nav.ToLower()).Replace( " ", "-" ) + ".dita"
            }
            elseif ( $lnstr.StartsWith( "title: " ) ) {
                MkHeader $lnstr.Substring( "title: ".Length ) $nav $prologfn $prestepsfn $tgtdir | Out-File $tgtfile -Encoding DEFAULT
                $openbodytag = $TRUE
            }

            elseif ( $lnstr.StartsWith( "note: " ) ) {
                MkNote $lnstr.Substring( "note: ".Length ) $bpfnbase | Out-File $tgtfile -Append -Encoding DEFAULT
            }

            # The following must be ordered from most specific to most general.
            elseif ( $lnstr.StartsWith( "#. step-pbar-" ) ) {
                $arr = ($lnstr.Substring( "#. step-pbar-".Length )).Split( " ", [System.StringSplitOptions]::None )
                MkStepPBar $arr[0] @($arr[1..($arr.length-1)]) | Out-File $tgtfile -Append -Encoding DEFAULT
            }
            elseif ( $lnstr.StartsWith( "#. step-" ) ) {
                MkStepBPLocal $lnstr.Substring( "#. ".Length ) $bpfnbase | Out-File $tgtfile -Append -Encoding DEFAULT
            }
            elseif ( $lnstr.StartsWith( "#. " ) ) {
                MkStepLiteral $lnstr.Substring( "#. ".Length ) | Out-File $tgtfile -Append -Encoding DEFAULT
            }

            elseif ( $lnstr.StartsWith( "#--" ) ) {
                StartSteps | Out-File $tgtfile -Append -Encoding DEFAULT
            }
            elseif ( $lnstr.StartsWith( "--#" ) ) {
                EndSteps | Out-File $tgtfile -Append -Encoding DEFAULT
            }

            elseif ( $lnstr.StartsWith( "result: " ) ) {
                MkResult $lnstr.Substring( "result: ".Length ) | Out-File $tgtfile -Append -Encoding DEFAULT
            }

        }

    }

    # For the last one.
    EndBody $openbodytag | Out-File $tgtfile -Append -Encoding DEFAULT
}
