# ======================================================================
# MkProducts
#
# WARNING: After running this, add the "release notes" to jobs-products.json. Do not rerun this script.
# ======================================================================


# GLOBAL VARIABLES -------------------------------------------

$global:urlprodversions = "http://localhost/docs/administrators/product-versions.html"
$global:urlprefix = "http://localhost/docs/administrators/release-notes/relnotes-"


# GENERAL FUNCTIONS ------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script infile outfile`r`n`tinfile lines must be tab-separated in the format: '2012 Nov 28	7.0.0	7.0.0	CodePlex	123456'"
    $examples = @(
        "powershell -file $script rels.txt rels.out"
        )

    Write-Host "Usage: " $usage
    Write-Host "Examples: "
    $examples | foreach { Write-Host "    " $_ }
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

function StrCompare( [string] $x, [string] $y, [boolean] $casesensitive )  {
    if ( !( $casesensitive ) )  {
        $x = $x.ToLower()
        $y = $y.ToLower()
    }
    if ( $x.CompareTo( $y ) -eq 0 )  {
        return $true
    }
    return $false
}

# Reference: https://blogs.technet.microsoft.com/heyscriptingguy/2011/05/10/use-the-pipeline-to-create-robust-powershell-functions/
function PrettifyJson  {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)] [string[]] $pipedjson
    )

    PROCESS {
        $tabs = ""
        $outstr = ""
        $arr = $input -split "`r`n"
        $newarr = @()
        foreach ( $ln in $arr )  {
            # do stuff here with $ln
            $lntrim = $ln.Trim().Replace( """releaseNotes"":  ""\r\n", """releaseNotes"":  """ )
            $lntrim = $lntrim.Replace( "\u003c", "<" ).Replace( "\u003e", ">" ).Replace( "\u0027", "\'" ).Replace( "\u0026", "&" )
            if (( $lntrim.StartsWith( "]" ) ) -or ( $lntrim.StartsWith( "}" ) ))  {
                $tabs = $tabs -replace "    \Z"
            }
            if ( IsValid $lntrim )   { $newarr += "$tabs$lntrim" }
            if (( $lntrim.EndsWith( "[" ) )   -or ( $lntrim.EndsWith( "{" ) ))    {
                $tabs += "    "
            }
        }
        $joined = $newarr -join "`r`n"
        Write-Output $joined
    }
}

# Source: http://avladov.com/blog/8/how-to-read-utf8-html-with-powershell
# Use this instead of Invoke-WebRequest + ParsedHtml.
function Read-HtmlPage {
    param ([Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)][String] $Uri)

    # Invoke-WebRequest and Invoke-RestMethod can't work properly with UTF-8 Response so we need to do things this way.
    [Net.HttpWebRequest]$WebRequest = [Net.WebRequest]::Create($Uri)
    [Net.HttpWebResponse]$WebResponse = $WebRequest.GetResponse()
    $Reader = New-Object IO.StreamReader($WebResponse.GetResponseStream())
    $Response = $Reader.ReadToEnd()
    $Reader.Close()

    # Create the document class
    [mshtml.HTMLDocumentClass] $Doc = New-Object -com "HTMLFILE"
    $Doc.IHTMLDocument2_write($Response)

    # Returns a HTMLDocumentClass instance just like Invoke-WebRequest ParsedHtml
    $Doc
}

function GetProdVersionInfo()  {
    $prodvers = Invoke-WebRequest $global:urlprodversions

    $arr = @()
    if ( $prodvers.StatusCode -eq 200 )  {
        $prodvers.ParsedHtml.getElementsByTagName( "tr" ) | foreach  {
            if ( !( StrCompare $_.childNodes[0].innerText "Release Date" ) )  {
                $reldate      = $_.childNodes[0].innerText
                $nodeP        = $_.childNodes[1]
                $nodeE        = $_.childNodes[2]
                $noderelnotes = $_.childNodes[3]

                $reldate  = ([datetime]$reldate).ToString( 'yyyy-MMM-dd' ).ToLower()
                # $verP     = $nodeP.children[0].innerText
                $repoloc  = $nodeP.children[1].innerText
                $repourl  = $nodeP.children[1] | Select-Object -Expand href
                # $verE     = $nodeP.children[2].innerText

                $node = [PSCustomObject]@{}
                $node | Add-Member -Type NoteProperty -Name "reldate" -Value $reldate
                # $node | Add-Member -Type NoteProperty -Name "verP"    -Value $verP
                $node | Add-Member -Type NoteProperty -Name "repoloc" -Value $repoloc
                $node | Add-Member -Type NoteProperty -Name "repourl" -Value $repourl
                # $node | Add-Member -Type NoteProperty -Name "verE"    -Value $verE
                $arr += $node
            }
        }
    }
    return $arr
}

function MkProdNode( [string] $prodname, [string] $fullname, [string] $ver, [string] $date, [string] $notes, [string] $repoloc, [string] $repourl )  {
    $node = [PSCustomObject]@{}
    $node | Add-Member -Type NoteProperty -Name "name" -Value $prodname
    $node | Add-Member -Type NoteProperty -Name "_fullname_" -Value $fullname
    $node | Add-Member -Type NoteProperty -Name "_ver_" -Value $ver
    $node | Add-Member -Type NoteProperty -Name "_unixdate_" -Value $date
    $node | Add-Member -Type NoteProperty -Name "releaseNotes" -Value $notes
    if ( IsValid $repoloc ) { $node | Add-Member -Type NoteProperty -Name "sourceLocation" -Value $repoloc }
    if ( IsValid $repourl ) { $node | Add-Member -Type NoteProperty -Name "sourceURL"      -Value $repourl }
    return $node
}
function GetRelNotesArr( [PSObject] $listnode )  {
    $srcurl = $global:urlprefix + $listnode.reldate + ".html"
    $srchtml = Read-HtmlPage $srcurl    # $srchtml = Invoke-WebRequest $srcurl

    $relnotesarr = @()

    # $dlularr = $srchtml.ParsedHtml.getElementsByTagName( "dl" ) + $srchtml.ParsedHtml.getElementsByTagName( "ul" )
    $dlularr = $srchtml.getElementsByTagName( "dl" ) + $srchtml.getElementsByTagName( "ul" )
    foreach ( $dlulnode in $dlularr )  {
        if ( ( $dlulnode.id ) -and ( $dlulnode.id.StartsWith( "top-relnotes-" ) ) )  {
            # Example id : top-relnotes-2012-nov-28__ul-relnotes-platform-7.0.0
            $cleanedid = ($dlulnode.id).Replace( "top-relnotes-", "" ) -replace "__[du]+l-relnotes", ""
            $idarr = $cleanedid.Split( "-", [System.StringSplitOptions]::None )
            $ver = $idarr[-1]
            $prodcode = $idarr[-2]
            $notes = $dlulnode.outerHtml

            switch ( $prodcode )  {
                "platform"  {
                    $fullname = "DNN Platform"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes $listnode.repoloc $listnode.repourl
                    break
                }
                "basic"  {
                    $fullname = "Evoq Basic"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    break
                }
                "content"  {
                    $fullname = "Evoq Content"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    break
                }
                "engage"  {
                    $fullname = "Evoq Engage"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    break
                }
                "contentplus"  {
                    $fullname = "Evoq Basic"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    $fullname = "Evoq Content"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    break
                }
                "evoq"  {
                    $fullname = "Evoq Basic"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    $fullname = "Evoq Content"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    $fullname = "Evoq Engage"
                    $relnotesarr += MkProdNode "product-$prodcode-$ver" $fullname $ver $listnode.reldate $notes
                    break
                }
            }
        }
    }

    return $relnotesarr
}



# MAIN -------------------------------------------------------

if ( $args.Count -gt 0 )  {
    $tgtfn = $args[0]

    $outarr = @()

    # Get the list of product versions from $global:urlprodversions
    $prodarr = GetProdVersionInfo

    # For each of the release dates, which products were released? Create nodes only for those that have release notes.
    foreach ( $listnode in $prodarr )  {
        $relnotesarr = GetRelNotesArr $listnode
        $outarr += $relnotesarr
    }

    Write-Output $outarr | ConvertTo-Json -Depth 100 | PrettifyJson | Out-File $tgtfn -Encoding "UTF8"   # DEFAULT
}
else  {
    Usage
}

# ============================================================
