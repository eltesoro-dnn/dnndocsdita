# Creates a web.config file.
# USAGE: powershell -file w:\_build\urlmap\urlmap.ps1 w:\_build\urlmap\DC-URLmapping.csv v:\output\html5 > web.config

if ( $args.Count -gt 1 )  {
    $legacycsv = $args[0]
	$bldoutdir = $args[1]

    # Prefix for web.config
	Write-Host( "<?xml version=""1.0"" encoding=""UTF-8""?>" )
	Write-Host( "<configuration>" )
	Write-Host( "    <system.webServer>" )
	Write-Host( "        <rewrite>" )
	Write-Host( "            <rules>" )
	Write-Host( "                <clear />" )

    $i = 1

    # Process the old paths from DCv1.0.
	foreach ( $ln in ( Import-Csv $legacycsv ) )
	{
        $old = $ln.old
        $new = $ln.new

        Write-Host( "                <rule name=""Rule-$global:i"" stopProcessing=""true"">" )

        # External links
        if ( $new.StartsWith( "http:" ) )
        {
            Write-Host( "                   <match url=""^(.*)$old$"" />" )
            Write-Host( "                   <action type=""Redirect"" url=""$new"" />" )
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

            Write-Host( "                   <match url=""^(.*)$old$suffixold$"" />" )
            Write-Host( "                   <action type=""Redirect"" url=""{R:1}$new$suffixnew"" />" )
        }

        Write-Host( "                </rule>" )
        $global:i++
	}

    # Get the subdirectories in $bldoutdir and create rules that add /index.html to the path.
	foreach ( $fn in ( Get-ChildItem -path $bldoutdir -recurse | Where-Object {$_.PSIsContainer -eq $True} ) )
	{
        $fnclean = $fn.FullName.SubString( $bldoutdir.Length + 1 ).Replace( "\", "/" )
        Write-Host( "                <rule name=""Rule-$global:i"" stopProcessing=""true"">" )
        Write-Host( "                   <match url=""^(.*)$fnclean$"" />" )
        Write-Host( "                   <action type=""Redirect"" url=""{R:1}$fnclean/index.html"" />" )
        Write-Host( "                </rule>" )
        $global:i++
	}

    # 85 folder
    Write-Host( "                <rule name=""Rule-$global:i"" stopProcessing=""true"">" )
    Write-Host( "                   <match url=""^(.*)85$"" />" )
    Write-Host( "                   <action type=""Redirect"" url=""{R:1}85/index.html"" />" )
    Write-Host( "                </rule>" )

    # Suffix for web.config
	Write-Host( "                <rule name=""LowerCaseRule1"" stopProcessing=""true"">" )
	Write-Host( "                    <match url=""[A-Z]"" ignoreCase=""false"" />" )
	Write-Host( "                    <action type=""Redirect"" url=""{ToLower:{URL}}"" />" )
	Write-Host( "                </rule>" )
	Write-Host( "            </rules>" )
	Write-Host( "        </rewrite>" )
	Write-Host( "        <handlers>" )
	Write-Host( "            <add name=""SSI-html"" path=""*.html"" verb=""*"" modules=""ServerSideIncludeModule"" resourceType=""Unspecified"" />" )
	Write-Host( "        </handlers>" )
	Write-Host( "    </system.webServer>" )
	Write-Host( "</configuration>" )

}
