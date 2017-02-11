# Deletes the specified file and creates a blank one.
# USAGE:   powershell -file refresh-files.ps1 file1.txt file2.xml file3.csv
# EXAMPLE: powershell -file refresh-files.ps1 *E90*csv

function RefreshFile( [string] $fn )  {
    Write-Output "Recreating $fn ...."
    if ( Test-Path -Path $fn )  {
        Remove-Item  $fn  -Force  | Out-Null
    }
    New-Item  $fn  -Type file  -Force | Out-Null
}

# MAIN
$args | foreach  {
    foreach ( $fn in Get-ChildItem -path $_ )  {
        RefreshFile $fn
    }
}
