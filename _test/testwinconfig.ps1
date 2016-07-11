# Tests web.config.
# USAGE: powershell -f W:\_test\testwinconfig.ps1 http://qa.dnncorp.biz/docs w:\_build\urlmap\DC-URLmapping.csv v:\4live-output\html5

function testUrl ( $url )
{
        $error.clear()

        try
        {
            $test = Invoke-WebRequest -method head -uri $url
        }
        catch
        {
            $errcode = $_.Exception.Response.StatusCode.Value__
            Write-Host( "*** Error $errcode $url" )
        }

        if ( !$error )
        {
            # $code = $test.StatusCode
            $desc = $test.StatusDescription
            Write-Host( "$desc $url" )
        }
}


if ( $args.Count -gt 2 )  {
    $UrlPrefix = $args[0]
    $legacycsv = $args[1]
	$bldoutdir = $args[2]

    # Test the old paths in $legacycsv.
    foreach ( $ln in ( Import-csv $legacycsv ) )
    {
        $url = $UrlPrefix + "/" + $ln.old
        testUrl( $url )
    }

    # Test the persona subdirectories in $bldoutdir
    $personalist = @( "administrators", "content-managers", "developers", "designers", "community-managers" )
    foreach ( $persona in $personalist )
    {
        $persdir = $bldoutdir + "/" + $persona
        foreach ( $fn in ( Get-ChildItem -path $persdir -recurse | Where-Object {$_.PSIsContainer -eq $True} ) )
        {
            $fnclean = $persona + "/" + $fn.FullName.SubString( $persdir.Length + 1 ).Replace( "\", "/" )
            $url = $UrlPrefix + "/" + $fnclean
            testUrl( $url )
            testUrl( $url + "/"  )
        }
    }

}
