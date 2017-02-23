# ============================================================
# Extracts the lines that should be in documented in Confluence.
# ============================================================

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script inputfn outputfn"
    $examples = @(
        "powershell -file $script mkbp-pbtabs-steps.out confluence.out"
        )

    Write-Host "Usage: " $usage
    Write-Host "Examples: "
    $examples | foreach { Write-Host "    " $_ }
}

function RefreshFile( [string] $fn )  {
    Write-Host "Recreating $fn ...."

    if ( Test-Path -Path $fn )  {
        Remove-Item  $fn  -Force  | Out-Null
    }
    New-Item  $fn  -Type file  -Force | Out-Null
}



# MAIN -------------------------------------------------------

if ( $args.Count -gt 1 )  {
    $src = $args[0]
    $tgt = $args[1]

    RefreshFile $tgt

    $lines =  Get-Content $src | Where { $_.Contains( "step conkeyref" ) }
    $lines += Get-Content $src | Where { $_.Contains( "li outputclass" ) }

    foreach ( $ln in $lines )  {
        $ln.Replace( "<!-- ", "" ).Replace( "-->", "" ).Trim() | Out-File $tgt -Append
    }

}
else  {
    Usage
}

# ============================================================

