# ============================================================
# Performs GET, POST, PUT, DELETE against the DNN APIs.
#
# Requirements?
# Output?
# Resource : https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.utility/invoke-webrequest
# ============================================================


# GLOBAL VARIABLES -------------------------------------------

$apiurl = "https://dnnapi.com/content/api"
$mimetype = "application/json"

# $APICALLS = @( "ContentTypes", "ContentItems" )
# $ACTIONS  = @( "GET", "POST", "PUT", "DELETE" )


# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script $setsjson $jobsjson $jobname"


    $examples = @(
        "powershell -file $script settings.json jobs-sections.json list-all-contenttypes"
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

# Gets the appropriate contenttype ID from the settings file, based on the contenttype embedded in the jobname.
function GetContentTypeID( [PSObject] $contenttypeids, [string] $jobname )  {
    foreach ( $name in $contenttypeids.psobject.properties.name )   {
        $namelc = "-" + $name.ToLower()
        if ( $jobname.ToLower().Contains( $namelc ) )  {
            return $contenttypeids.$name
        }
    }
    return ""
}

# Gets the image ID from the settings file, based on the value of _imageciname_ in the permutation.
function GetImageID( [PSObject] $imageids, [string] $imageciname )  {
    foreach ( $name in $imageids.psobject.properties.name )   {
        if ( $jobname.ToLower().CompareTo( $name.ToLower() ) -eq 0 )  {
            return $imageids.$name
        }
    }
    return ""
}

# Wraps each element of an array inside <span/> tags with the specified class.
function WrapSpanElements( [string[]] $arr, [string] $class )  {
    $new = @()
    $arr | foreach  {
        $new = "&lt;span class=&quot;$class&quot;&gt;$_&lt;/span&gt;"
    }
    return $new
}

# Returns the Unixtime epochtime of a date in the format "yyyy-MMM-dd".
function GetUnixDate( [string] $reldate )  {
    $d1 = Get-Date -Date "01/01/1970"
    $d2 = [datetime]::ParseExact( $reldate, 'yyyy-MMM-dd', $null )
    $u = (New-TimeSpan -Start $d1 -End $d2).TotalSeconds + 43200   # BUGBUG: Noon.
    return $u
}

# Replaces the values of the keys in $tgtnode with the values of the same keys in $legendnode. Recursive.
function ReplaceWithLegend( [PSCustomObject] $tgtnode, [PSCustomObject] $legendnode )  {
    $legendkeys = @( $legendnode.psobject.properties.name )
    if ( $tgtnode -is [PSCustomObject] )  {
        foreach ( $key in $tgtnode.psobject.properties.name )  {
            if ( $legendkeys.Contains($key) )  {
                $tgtnode.$key = $legendnode.$key
            }
            if ( $tgtnode.$key -is [PSCustomObject] )  {
                $tgtnode.$key = ReplaceWithLegend $tgtnode.$key $legendnode
            }
        }
    }
    return $tgtnode
}

# Returns one permutation.
function MkPerm( [string] $template, [PSCustomObject] $perm )  {

    $ignorearr = @( "id" )
    foreach ( $key in $perm.psobject.properties.name ) {
        if ( $ignorearr -notcontains $key )  {
            $newval = $perm.$key
            switch ( $key )  {
                "_dashed_"    {
                    if ( $newval -is [array] )  {
                        $newval = [string]::Join( "-", $newval )
                        $newval = $newval.Replace( " ", "" ).Replace( "/", "" ).ToLower()
                    }
                    $template = $template.Replace( $key, $newval )
                }
                "_menucasc_"  {
                    if ( $newval -is [array] )  {
                        $arr = WrapSpanElements $newval "ph uicontrol"
                        $newval = "&lt;span class=&quot;menucascade&quot;&gt;" + [string]::Join( " &gt; ", $arr ) + "&lt;/span&gt;"
                    }
                    $template = $template.Replace( $key, $newval )
                }
                "_menualt_"  {
                    if ( $newval -is [array] )  {
                        $newval = [string]::Join( " &gt; ", $newval )
                    }
                    $template = $template.Replace( $key, $newval )
                }
                "_unixdate_"  {
                    $newval = GetUnixDate( $newval )

                    $template = $template.Replace( $key, $newval )
                    $template = $template.Replace( """$key""", $newval )
                }
                "_int_"  {
                    $template = $template.Replace( $key, $newval )
                    $template = $template.Replace( """$key""", $newval )
                }
                "_imageid_"  {
                    if ( $perm._imageciname_ )  { $newval = GetImageID $imageids $perm._imageciname_ }
                    else                        { $newval = "" }
                    $template = $template.Replace( $key, $newval )
                }
                DEFAULT  {
                    $template = $template.Replace( $key, $newval )
                }
            }
        }
    }
    return $template
}

function ProcessPermutations( [string] $action, [PSObject] $node, [string] $id )  {
    $template = $node.body | ConvertTo-Json -Depth 10

    if ( $node.permutations -is [array] )  {
        foreach ( $perm in $node.permutations )  {
            if ( IsValid $perm.id )  {  $id = "/" + $perm.id  }
            $body = MkPerm $template $perm
            Write-Host "*** Query : $apiurl$apicall$id$query"
            Write-Host "*** Body  : `n$body"
            $response = Invoke-WebRequest  -URI "$apiurl$apicall$id$query"  -Method $action  -Body $body  -ContentType $mimetype  -Headers $hdr
        }
    }

    else  {
        Write-Host "*** Query: $apiurl$apicall$id$query"
        Write-Host "*** Body  : `n$template"
        $response = Invoke-WebRequest  -URI "$apiurl$apicall$id$query"  -Method $action  -Body $template  -ContentType $mimetype  -Headers $hdr
    }

    return $response
}

# Invokes the web request.
function MkWebRequest( [string] $action, [PSCustomObject] $node )  {
    switch( $action )  {

        "GET"    {
            # ID of the object to get
            if ( IsValid $node.id )  {  $id = "/" + $node.id  }
            Write-Host "*** Query: $apiurl$apicall$id$query"
            $response = Invoke-WebRequest  -URI "$apiurl$apicall$id$query"  -Method $action  -ContentType $mimetype  -Headers $hdr
        }

        "POST"   {
            $response = ProcessPermutations $action $node
        }

        "PUT"    {
            # ID of the object to update
            if ( IsValid $node.id )  {  $id = "/" + $node.id  }
            $response = ProcessPermutations $action $node $id
        }

        "DELETE" {
            # ID of the object to delete
            if     ( $node.id -is [string] )  {  $idlist = @( $node.id )  }
            elseif ( $node.id -is [array] )   {  $idlist = $node.id  }
            $idlist | foreach  {
                if ( IsValid $_ )  {
                    Write-Host "*** Query: $apiurl$apicall/$_$query"
                    $response = Invoke-WebRequest  -URI "$apiurl$apicall/$_$query"  -Method $action  -ContentType $mimetype  -Headers $hdr
                }
            }
        }

        DEFAULT  {
        }
    }

    return $response
}

function MkPSObjForSettings( [PSObject] $respjsondocs )  {
    $outobj = [PSCustomObject]@{}
    $respjsondocs | foreach  {
        $k = $_.name.ToLower()
        $v = $_.id
        try    { $outobj | Add-Member -Name $k -Type NoteProperty -Value $v }
        catch  { Write-Host "WARNING: A duplicate of $k was found." }
    }
    return $outobj
}


# MAIN -------------------------------------------------------

if ( $args.Count -gt 1 )  {
    $setsjson = $args[0]
    $jobsjson = $args[1]
    $jobname  = $args[2]

    $thisscript = $MyInvocation.MyCommand.Name
    $params = [string]::Join( " ", $args )



    # Read the settings file.
    $mysettings = Get-Content -Raw -Path $setsjson | ConvertFrom-Json
    if ( IsValid $mysettings.apikey )          {  $apikey   = $mysettings.apikey  }
    if ( IsValid $mysettings.outraw )          {  $outraw   = $mysettings.outraw  }
    if ( IsValid $mysettings.contenttypeids )  {  $ctypes   = $mysettings.contenttypeids  }
    if ( IsValid $mysettings.imageids )        {  $imageids = $mysettings.imageids  }


    # Compose the header.
    if ( $apikey -eq $NULL )  {
        Write-Error "ERROR: Null apikey setting in $setsjson."
        return
    }
    $hdr = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $hdr.Add( "Authorization", "Bearer " + $apikey )
    $hdr.Add( "Cache-Control", "no-cache, no-store, must-revalidate" )



    # Read the jobs file.
    $myjobs = Get-Content -Raw -Path $jobsjson | ConvertFrom-Json

    if ( $myjobs.$jobname -is [PSCustomObject] )  {
        $jobnode = $myjobs.$jobname

        # Do global replacements from the site settings.
        $fields = $jobnode.body.fields
        foreach ( $fld in $fields )  {
            # If there are references to another contenttype, check if that contenttype already exists.
            if ( IsValid $fld.allowedContentTypeName )  {
                $ctypename = $fld.allowedContentTypeName
                if ( $ctypes.psobject.properties.name -contains $ctypename )   {
                    $fld.allowedContentTypeId = $ctypes.$ctypename
                }
                else {
                    Write-Error "ERROR: You must first run: `n`t powershell -file $script $setsjson json\jobs-contenttypes.json add-contenttype-$ctypename `n`t powershell -file $script $setsjson json\jobs-contenttypes.json list-all-contenttypes"
                    return
                }
            }
        }

        # Do global replacements from the legend.
        if ( $myjobs.legend -is [PSCustomObject] )  {
            $legendnode = $myjobs.legend
            if ( $legendnode.contentTypeId -eq "" )  {
                $legendnode.contentTypeId = GetContentTypeID $ctypes $jobname
            }
            $jobnode = ReplaceWithLegend $jobnode $legendnode
        }

        # $action and $apicall are required.
        $missing = @()
        if ( $jobnode.action  -eq $NULL )  {  $missing += "action"  }
        if ( $jobnode.apicall -eq $NULL )  {  $missing += "apicall"  }
        if ( $missing.Count -gt 0 )  {
            $s = [string]::Join( ", ", $missing )
            Write-Host "ERROR: Null settings in $jobsjson - $s"
            return
        }
        if ( IsValid $jobnode.apicall )  { $apicall = "/" + $jobnode.apicall }

        # Query
        if ( $jobnode.query -is [PSCustomObject] )  {
            $querynode = $jobnode.query
            $queryarr = @()
            foreach ( $name in $querynode.psobject.properties.name )  {
                if (( $name.CompareTo( "contentTypeId" ) -eq 0 ) -and ( IsNotValid( $querynode.$name ) ))  {
                    $val = $contenttypeid
                }
                else  {
                    $val = $querynode.$name
                }
                $queryarr += "$name=$val"
            }
            $query = "/?" + [string]::Join( "&", $queryarr )
        }
    }



    # What to do based on the $action.
    if ( IsValid $jobnode.testdesc )  {
        $testdesc = $jobnode.testdesc
        Write-Host "*** Job : $jobname - $testdesc"
    }
    if ( $jobnode.action -eq "GET-DELETE" )  {
        $response = MkWebRequest "GET" $jobnode
        if ( $response )  {
            $respjson = $response | ConvertFrom-Json
            $idlist = @()
            $respjson.documents | foreach  {
                if ( !($_.isSystem) )  {
                    $idlist += $_.id
                }
            }
            $jobnode.id = $idlist
            $response = MkWebRequest "DELETE" $jobnode
            if ( $response )  {
                $respjson = $response | ConvertFrom-Json
            }
        }
    }
    else  {
        $response = MkWebRequest $jobnode.action $jobnode
        if ( $response )  {
            $respjson = $response | ConvertFrom-Json
        }
    }



    # Results

    ## raw
    if ( IsValid $outraw )  {  Write-Output $response.content | Out-File $outraw -Encoding DEFAULT  }

    ## With list-* jobs, display the key-value pairs to the console.
    $outfile  = $jobnode.outfile
    if ( IsValid $outfile )  {
        $respjson.documents | foreach  {
            $id = $_.id
            $name = $_.name
            Write-Output """$name"" : ""$id"""
        } | Out-File $outfile -Encoding DEFAULT
        $outfile | Out-Host
    }

    ## With list-all-contenttypes, update the list of contenttypeids in $setsjson.
    $jobarr = @( "list-all-contenttypes" )
    if ( $jobarr -contains $jobname  )  {
        $mysettings.contenttypeids = MkPSObjForSettings $respjson.documents
        $mysettings | ConvertTo-Json -Depth 10 | Out-File $setsjson -Encoding DEFAULT
    }

    ## With list-all-type-images, update the list of imageids in $setsjson.
    $jobarr = @( "list-all-type-images" )
    if ( $jobarr -contains $jobname  )  {
        $mysettings.imageids = MkPSObjForSettings $respjson.documents
        $mysettings | ConvertTo-Json -Depth 10 | Out-File $setsjson -Encoding DEFAULT
    }

}
else  {
    Usage
}


# ============================================================
