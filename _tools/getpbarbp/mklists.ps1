# ============================================================
# Extracts the boilerplate calls to use from the boilerplate dita file.
# ============================================================

# GLOBAL VARIABLES -------------------------------------------

# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script boilerplatefile outputfile"
    $examples = @(
        "powershell -file $script w:\_content\common\bptext-pbar.dita   pbarbplist.txt"
        "powershell -file $script w:\_content\common\bptext-pbtabs.dita tagsbplist.txt"
        )

    Write-Host "Usage: " $usage
    Write-Host "Examples: "
    $examples | foreach { Write-Host "    " $_ }
}


# MAIN -------------------------------------------------------

if ( $args.Count -gt 1 )  {
    $bpfn = $args[0]
    $lsfn = $args[1]

    New-Item $lsfn  -Type file  -Force | Out-Null

    Get-Content $bpfn | Where { $_.Contains( "<!-- <step conkeyref" ) -or $_.Contains( "<!-- <li outputclass" ) } | foreach {
        $_ -match "<!-- (?<content>.*) -->" | Out-Null; $matches['content']
    } | Out-File $lsfn

}
else  {
    Usage
}

# ============================================================
