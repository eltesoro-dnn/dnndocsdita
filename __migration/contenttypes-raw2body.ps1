# ============================================================
# Converts the results of a GET contenttype to body for dnnps.ps1.
#
# Requirements?
# Output?
# ============================================================


# GLOBAL VARIABLES -------------------------------------------



# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script $raw $out"


    $examples = @(
        "powershell -file $script out\contenttypes-raw.out out\jobs-contenttypes.out"
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


# Create the job.
function InitJob()  {
    $query = [PSCustomObject]@{
        publish = "TRUE"
    }

    $object = [PSCustomObject]@{
        action = "POST"
        apicall = "ContentTypes"
        query = $query
        body = @{}
    }

    return $object
}

# Delete the properties listed in the array if the first property is set to false or is blank.
function DeleteIfFirstIsFalseOrInvalid( [PSObject] $node, [string[]] $props )  {
    $first = $props[0]
    if ( ( !($node.$first) ) -or ( IsNotValid $node.$first ) ) {
        foreach( $prop in $props )  {
            $node = $node | Select-Object * -ExcludeProperty $prop
        }
    }
    return $node
}
# Delete the properties we don't want. Recursive.
function CleanNode( [PSObject] $node )  {
    $excludeprops  = @(
        "id",
        "createdAt",
        "createdBy",
        "updatedAt",
        "updatedBy",
        "numberOfItems",
        "numberOfVisualizers",
        "isSystem"
    )
    foreach ( $prop in $excludeprops )  {
        $node = $node | Select-Object * -ExcludeProperty $prop
    }

    $node = DeleteIfFirstIsFalseOrInvalid $node @( "descriptionActive", "description" )
    $node = DeleteIfFirstIsFalseOrInvalid $node @( "tooltipActive", "tooltip" )
    $node = DeleteIfFirstIsFalseOrInvalid $node @( "defaultValue", "setDefaultValueAsHidden" )

    if ( IsValid $node.allowedContentTypeId )  {
        $node.allowedContentTypeId = ""
    }

    if ( $node.fields -is [array] )  {
        for ( $i = 0; $i -le ($node.fields).GetUpperBound(0); $i++ ) {
            ($node.fields)[$i] = CleanNode ($node.fields)[$i]
        }
    }

    if ( $node.properties -is [PSObject] )  {
        foreach ( $name in $node.properties.psobject.properties.name )  {
            $node.properties.$name = CleanNode $node.properties.$name
        }
    }

    if ( $node.validation -is [PSObject] )  {
        $excludevalidations = @(
            "requireField",
            "numberOfCharacters",
            "standardErrorMessage",
            "*"
        )
        foreach ( $prop in $excludevalidations )  {
            if ( ( !($node.validation.$prop.active) ) -or ( IsNotValid $node.validation.$prop ) )  {
                $node.validation = $node.validation | Select-Object * -ExcludeProperty $prop
            }
        }
        if ( $node.validation.Count -lt 1 ) {
            $node = $node | Select-Object * -ExcludeProperty "validation"
        }
    }

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


# MAIN -------------------------------------------------------

if ( $args.Count -gt 1 )  {
    $in = $args[0]
    $out = $args[1]

    $thisscript = $MyInvocation.MyCommand.Name
    $params = [string]::Join( " ", $args )

    Write-Output "" | Out-File $out -Encoding DEFAULT


    # Default jobs.
    $outobj = [PSCustomObject]@{
        "list-all-contenttypes" = [PSCustomObject]@{}
        "deleteall-contenttypes" = [PSCustomObject]@{}
    }


    # Read the input file.
    $injson = Get-Content -Raw -Path $in | ConvertFrom-Json
    foreach ( $ctype in $injson.documents )  {
        if ( !($ctype.isSystem) )  {
            $name = "add-contenttype-" + $ctype.name
            Write-Host "Name: $name"
            $newjob = InitJob
            $outobj | Add-Member -Type NoteProperty -Name $name -Value $newjob
            $outobj.$name.body = CleanNode $ctype
        }
    }
    Write-Output $outobj | ConvertTo-Json -Depth 10 | Format-Json | Out-File $out -Encoding DEFAULT -Append
}
else  {
    Usage
}


# ============================================================
