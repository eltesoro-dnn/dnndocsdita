# Creates the boilerplates for the Persona Bar menu (usually Step 1).
# USAGE: powershell -file extract.ps1 mkbp-pbar.csv E85cmg

# MAIN
if ( $args.Count -gt 1 )  {
    $srccsv = $args[0]
    $colname = $args[1]
    $tgtcsv = "pbar-" + $colname + ".csv"

    ( import-csv $srccsv ) | where-object { $_.$colname -ne "" } | sort-object $colname | select-object menu1,menu2 | export-csv $tgtcsv

}
