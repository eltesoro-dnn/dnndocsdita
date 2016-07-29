# Reads two file and replaces the captions, assumed to start at line 3, then every four lines thereafter.
# USAGE: powershell -file w:\_video\synccaptions.ps1 EnglishCaptions.srt OtherLangCaptions.srt output.srt

if ( $args.Count -gt 2 )  {
    $fileA = $args[0]
    $fileB = $args[1]
    $outfile = $args[2]

    $arrB = Get-Content $fileB

    $i = 0
    $j = 2
    $interval = 4

    foreach ( $ln in Get-Content $fileA )
    {
        if ( $i -eq $j )
        {
            $arrB[$j] | Out-File $outfile -encoding "UTF8" -append
            $j += $interval
        }
        else
        {
            $ln | Out-File $outfile -encoding "UTF8" -append
        }
        $i++;
    }
}
