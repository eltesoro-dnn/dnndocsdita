# ============================================================
# What does the script do?
#
# Requirements?
# Output?
# ============================================================


# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script infile outfile"
    $examples = @(
        "powershell -file $script json\jobs-contenttypes.json createcontenttypes.txt"
        )

    Write-Host "Usage: " $usage
    Write-Host "Examples: "
    $examples | foreach { Write-Host "    " $_ }
}

function Pause()  {
    Write-Host "Press any key to continue ..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") | Out-Null
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

function AddKeyValue( [PSObject] $node, [string] $key, $value )  {
    $node | Add-Member -Type NoteProperty -Name $key -Value $value
    return $node
}

# Formats JSON in a nicer format than the built-in ConvertTo-Json does.
# Source: https://github.com/PowerShell/PowerShell/issues/2736
function Format-Json([Parameter(Mandatory, ValueFromPipeline)][String] $json) {
  $indent = 0;
  ($json -Split '\n' |
    % {
      if ($_ -match '[\}\]]') {
        # This line contains  ] or }, decrement the indentation level
        $indent--
      }
      $line = (' ' * $indent * 4) + $_.TrimStart().Replace(':  ', ': ')
      if ($_ -match '[\{\[]') {
        # This line contains [ or {, increment the indentation level
        $indent++
      }
      $line
  }) -Join "`n"
}

function AddToOutArr( [PSObject] $outobj, [string] $name, [string[]] $outarr )  {
    if (( IsValid $name ) -and ( $outarr -notcontains $name ))  {
        if ( $outobj.$name.Length -gt 0 )  {
            foreach ( $dep in $outobj.$name )  {
                if ( $outarr -notcontains $dep )  {
                    AddToOutArr $outobj $dep $outarr
                    $outarr += $dep
                }
            }
            $joined = [string]::Join( ", ", $outobj.$name )
            Write-Output "`r`n:. Requires $joined" | Out-File $out -Encoding DEFAULT -Append
        }
        $outarr += $name
        Write-Output "call dnnps.bat add-contenttype-$name" | Out-File $out -Encoding DEFAULT -Append
    }
    return $outarr
}

function MkOutArr( [PSObject] $outobj, [string] $typename, [string[]] $outarr )  {
    if ( $outarr -notcontains $typename  )  {
        if ( $outobj.$typename.Length -gt 0 )  {
            $deparr = @()
            foreach ( $dep in $outobj.$typename )  {
                if ( $outarr -notcontains $dep )  {
                    $deparr += MkOutArr $outobj $dep $outarr
                }
            }
            $deparr += $typename
        }
        return $deparr
    }
    else {
        return $null
    }
}


# GLOBAL VARIABLES -------------------------------------------

$global:foo = @()


# MAIN -------------------------------------------------------

if ( $args.Count -gt 1 )  {
    $in = $args[0]
    $out = $args[1]

    $outobj = [PSCustomObject]@{}

    $injson = Get-Content -Raw -Path $in | ConvertFrom-Json
    foreach ( $jobname in $injson.psobject.properties.name )  {
        if (( $jobname.StartsWith( "add" ) ) -and !( $jobname.StartsWith( "add-contenttype-Test" )))  {
            $arr = @()
            foreach ( $fld in $injson.$jobname.body.fields )  {
                if (( $fld.allowedContentTypeName ) -and ( $arr -notcontains $fld.allowedContentTypeName ))  {
                    $arr += $fld.allowedContentTypeName.Replace( " ", "" )
                }
            }
            $key = $injson.$jobname.body.name.Replace( " ", "" )
            $outobj | Add-Member -Type NoteProperty -Name $key -Value $arr
        }
    }

    Write-Output "@echo off" | Out-File $out -Encoding DEFAULT
    Write-Output "    call dnnps.bat listall-contenttypes`r`n" | Out-File $out -Encoding DEFAULT -Append
    foreach ( $typename in $outobj.psobject.properties.name )  {
        if ( $outobj.$typename.Length -gt 0 )  {
            $deps = $outlist = [string]::Join( ", ", $outobj.$typename )
            Write-Output "`r`n:. Requires $deps" | Out-File $out -Encoding DEFAULT -Append
        }
        Write-Output "call dnnps.bat add-contenttype-$typename" | Out-File $out -Encoding DEFAULT -Append
        Write-Output "    call dnnps.bat listall-contenttypes`r`n" | Out-File $out -Encoding DEFAULT -Append
    }

    # Write-Output $outobj | ConvertTo-Json -Depth 10 | Format-Json | Out-File $out -Encoding DEFAULT


    # $outarr = @()
    # foreach ( $typename in $outobj.psobject.properties.name )  {
    #
    #
    #
    # }
    #
    #
    # Write-Output "@echo off" | Out-File $out -Encoding DEFAULT
    # Write-Output "    call dnnps.bat listall-contenttypes`r`n" | Out-File $out -Encoding DEFAULT -Append
    # Write-Output "    call dnnps.bat listall-contenttypes`r`n" | Out-File $out -Encoding DEFAULT -Append
    #
    # $outlist = [string]::Join( "`r`n`t", $outarr )
    # Write-Host "`n`nDEBUG: `n`t$outlist"
}
else  {
    Usage
}

# ============================================================


