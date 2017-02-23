# ============================================================
# Creates a web.config file.
# USAGE: powershell -file w:\_build\urlmap\urlmap.ps1 w:\_build\urlmap\DC-URLmapping.csv v:\output\html5 web.config
# ============================================================


function Write-Prefix()  {
    # Prefix for web.config
	Write-Output( "<?xml version=""1.0"" encoding=""UTF-8""?>" )
	Write-Output( "<configuration>" )
	Write-Output( "    <system.webServer>" )
	Write-Output( "        <rewrite>" )
	Write-Output( "            <rules>" )
	Write-Output( "                <clear />" )
}


function Process-Line( [string] $old, [string] $new, [int] $rulenum )  {
    Write-Output( "                <rule name=""Rule-$rulenum"" stopProcessing=""true"">" )

    # External links
    if ( $new.StartsWith( "http:" ) )
    {
        Write-Output( "                   <match url=""^(.*)$old$"" />" )
        Write-Output( "                   <action type=""Redirect"" url=""$new"" />" )
    }

    # Internal links
    else
    {
        # These suffixes are for directory name changes only. WARNING: Use with care; matches the prefix of $old, so the directory $oldanything will be replaced.
        $suffixold = ""
        $suffixnew = ""
        if ( -Not $new.EndsWith( ".html" ) )
        {
            $suffixold = "(.*)"
            $suffixnew = "{R:2}"
        }

        Write-Output( "                   <match url=""^(.*)$old$suffixold$"" />" )
        Write-Output( "                   <action type=""Redirect"" url=""{R:1}$new$suffixnew"" />" )
    }

    Write-Output( "                </rule>" )
}


function IndexHtmlRules( [string] $dirname, [int] $i )  {
    $fnclean = $dirname.SubString( $bldoutdir.Length + 1 ).Replace( "\", "/" )
    Write-Output( "                <rule name=""Rule-$i"" stopProcessing=""true"">" )
    Write-Output( "                   <match url=""^(.*)$fnclean$"" />" )
    Write-Output( "                   <action type=""Redirect"" url=""{R:1}$fnclean/index.html"" />" )
    Write-Output( "                </rule>" )
}


function Write85Folder( [int] $i )  {
    Write-Output( "                <rule name=""Rule-$i"" stopProcessing=""true"">" )
    Write-Output( "                   <match url=""^(.*)85$"" />" )
    Write-Output( "                   <action type=""Redirect"" url=""{R:1}85/index.html"" />" )
    Write-Output( "                </rule>" )
}


function WriteSuffix( [int] $i )  {
    # Suffix for web.config
	Write-Output( "                <rule name=""LowerCaseRule1"" stopProcessing=""true"">" )
	Write-Output( "                    <match url=""[A-Z]"" ignoreCase=""false"" />" )
	Write-Output( "                    <action type=""Redirect"" url=""{ToLower:{URL}}"" />" )
	Write-Output( "                </rule>" )
	Write-Output( "            </rules>" )
	Write-Output( "        </rewrite>" )

    <# Removed this after the move to Azure servers.
	Write-Output( "        <handlers>" )
	Write-Output( "            <add name=""SSI-html"" path=""*.html"" verb=""*"" modules=""ServerSideIncludeModule"" resourceType=""Unspecified"" />" )
	Write-Output( "        </handlers>" )
    #>

	Write-Output( "    </system.webServer>" )
	Write-Output( "</configuration>" )
}


function RefreshFile( $fn )  {
    Write-Host "Recreating $fn ...."

    if ( Test-Path -Path $fn )  {
        Remove-Item  $fn  -Force  | Out-Null
    }
    New-Item  $fn  -Type file  -Force | Out-Null
}


# MAIN -------------------------------------------------------

if ( $args.Count -gt 2 )  {
    $legacycsv = $args[0]
	$bldoutdir = $args[1]
    $outfile   = $args[2]

    RefreshFile $outfile

    Write-Prefix | Out-File  -FilePath $outfile  -Encoding "Default"

    $i = 1

    # Process the old paths from DCv1.0.
	Import-Csv $legacycsv | foreach  {
        Process-Line $_.old $_.new $i | Out-File  -FilePath $outfile  -Encoding "Default"  -Append
        $i++
	}

    # Get the subdirectories in $bldoutdir and create rules that add /index.html to the path.
	foreach ( $fn in ( Get-ChildItem -Path $bldoutdir -Recurse | Where-Object { $_.PSIsContainer -eq $True } ) )
	{
        IndexHtmlRules $fn.FullName $i | Out-File  -FilePath $outfile  -Encoding "Default"  -Append
        $i++
	}

    Write85Folder $i | Out-File  -FilePath $outfile  -Encoding "Default"  -Append
    $i++

    WriteSuffix | Out-File  -FilePath $outfile  -Encoding "Default"  -Append
}

# ============================================================
