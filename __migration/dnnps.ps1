# ============================================================
# Performs GET, POST, PUT, DELETE against the DNN APIs.
#
# Requirements?
# Output?
# Resource : https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.utility/invoke-webrequest
#
# ============================================================


# GLOBAL VARIABLES -------------------------------------------

$apiurl = "https://dnnapi.com/content/api"
$mimetype = "application/json"
$maxitems = 100


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

function StrCompare( [string] $x, [string] $y, [boolean] $casesensitive )  {
    if ( !( $casesensitive ) )  {
        $x = $x.ToLower()
        $y = $y.ToLower()
    }
    if ( $x.CompareTo( $y ) -eq 0 )  {
        return $true
    }
    return $false
}

function PSObj2Str( [PSObject] $queryobj, [string] $separator )  {
    $queryarr = @()
    foreach ( $name in $queryobj.psobject.properties.name )  {
        $val = $queryobj.$name
        $queryarr += "$name=$val"
    }
    return [string]::Join( $separator, $queryarr )
}


# Gets the contenttype ID from the settings file, based on the contenttype embedded in the jobname.
function GetContentTypeNameID( [string] $jobname, [PSObject] $ctypeidlist )  {
    $arr = @()
    foreach ( $name in $ctypeidlist.psobject.properties.name )   {
        $namelc = "-" + $name.ToLower()
        if ( $jobname.ToLower().Contains( $namelc ) )  {
            $arr = @( $name, $ctypeidlist.$name )
        }
    }
    return $arr
}

# Gets the contentitem ID from the settings file, based on the contenttype and the contentitem name.
# BUGBUG: Accesses the $mysettings var directly.
function GetContentItemID( [string] $contenttypename, [string] $contentitemname )  {
    $nodename = $contenttypename + "ids"
    $node = $mysettings.$nodename
    foreach ( $name in $node.psobject.properties.name )   {
        if ( StrCompare $contentitemname $name )  {
            # if there's only one, return it.
            if ( $node.$name -is [string] )  {
                return $node.$name
            }
            # if an array, return only the first.
            elseif ( $node.$name -is [array] )  {
                return ($node.$name)[0]
            }
            else  {
                return ""
            }
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
# To add key-value pairs that don't exist in $tgtnode, set $addmissing to $true.
# BUGBUG: Directly accesses $ctypenameid.
function ReplaceWithLegend( [PSCustomObject] $tgtnode, [PSCustomObject] $legendnode, [Bool] $addmissing )  {
    if ( $tgtnode -is [PSCustomObject] )  {
        $legendkeys = @( $legendnode.psobject.properties.name )
        $targetkeys = @( $tgtnode.psobject.properties.name )

        foreach ( $key in $targetkeys )  {
            if ( StrCompare $key "contentTypeId" )  {
                $tgtnode.contentTypeId = $ctypenameid[1]
            }
            if ( $legendkeys -contains $key )  {
                $tgtnode.$key = $legendnode.$key
            }
            if ( $tgtnode.$key -is [PSCustomObject] )  {
                $tgtnode.$key = ReplaceWithLegend $tgtnode.$key $legendnode $addmissing
            }
        }
        if ( $addmissing )  {
            foreach ( $key in $legendkeys )  {
                if ( $targetkeys -notcontains $key )  {
                    $tgtnode | Add-Member -Type NoteProperty -Name $key -Value $legendnode.$key
                }
            }
        }
    }
    return $tgtnode
}

function IsContentType( [string] $jobname )  {
    $arr = $jobname.Split( "-_", [System.StringSplitOptions]::None )
    if ( $arr[1].ToLower().StartsWith( "contenttype" ) )  { return $true }
    else                                                  { return $false }
}

function GetAction( [string] $jobname )  {
    if ( $jobname.StartsWith( "list-"      ) )  { return "GET" }
    if ( $jobname.StartsWith( "add-"       ) )  { return "POST" }
    if ( $jobname.StartsWith( "update-"    ) )  { return "PUT" }
    if ( $jobname.StartsWith( "delete-"    ) )  { return "DELETE" }
    if ( $jobname.StartsWith( "deleteall-" ) )  { return "GET-DELETE" }
}

function GetAPICall( [string] $jobname )  {
    if ( IsContentType $jobname )  { return "ContentTypes" }
    else                           { return "ContentItems" }
}

function GetContentTypeID( [string] $jobname )  {
    $arr = $jobname.Split( "-_", [System.StringSplitOptions]::None )
    return $arr[1]
}

function GetJobPrefix( [string] $jobname, [int32] $count )  {
    $arr = $jobname.Split( "-_", [System.StringSplitOptions]::None )
    $i = $count - 1
    return [string]::Join( "-", $arr[0..$i] )
}

# If the key already exists, updates the value of an existing key; otherwise, creates a new key-value pair.
function CreateOrUpdateNode( [PSObject] $parent, [string] $key, [string] $valstr, [PSObject] $valobj )  {
    if     ( IsValid $valstr )  { $value = $valstr }
    elseif ( IsValid $valobj )  { $value = $valobj }

    if ( $parent.$key )  {
        $parent.$key = $value
    }
    else {
        $parent | Add-Member -Type NoteProperty -Name $key -Value $value
    }

    return $parent
}

# For content types only. If $jobnode.body.fields includes references to another contenttype, check if that contenttype already exists. If it exists, get its ID; otherwise, error message.
function ReplaceRefsToOtherCTs( [PSObject] $jobnode )  {
    #  Get IDs of referenced contenttypes from the site settings.
    $jobnode.body.fields | foreach  {
        if ( IsValid $_.allowedContentTypeName )  {
            $ctypename = $_.allowedContentTypeName
            $ctid = GetContentTypeID $ctypename
            if ( IsValid $ctid )   {
                $_.allowedContentTypeId = $ctid
            }
            else {
                Write-Error "ERROR: You must first add the content type $ctypename."
                return $null
            }
        }
    }
    return $jobnode
}

# Returns one permutation.
function MkPerm( [PSCustomObject] $body, [PSCustomObject] $perm )  {
    $ignorearr = @( "id" )

    # Do not copy non-existent _*_ keys.
    $body = ReplaceWithLegend $body $perm $false

    # Convert to string for easier replacements.
    $template = $body | ConvertTo-Json -Depth 10

    # Replace the _*_ vars.
    foreach ( $key in $perm.psobject.properties.name ) {
        if (( $ignorearr -notcontains $key ) -and ( $key.StartsWith( "_" ) ))  {
            # Get the ID of the referenced content item.
            # Example: "_id-ctype-foo_" = "nameofmycontentitem" will get the ID of the content item "foo" of type "ctype".
            $newval = $perm.$key
            if ( $key.StartsWith( "_id-" ) )  {
                $arr = $key.Split( "-_", [System.StringSplitOptions]::None )
                $newval = GetContentItemID $arr[1].ToLower() $newval
            }

            switch ( $key )  {
                "_dashed_"    {
                    if ( $newval -is [array] )  {
                        $newval = [string]::Join( "-", $newval )
                        $newval = $newval.Replace( " ", "" ).Replace( "/", "" ).ToLower()
                    }
                    $template = $template.Replace( $key, $newval )
                }
                "_uicontrol_"  {
                    $newval = "&lt;span class=&quot;uicontrol&quot;&gt;" + $newval + "&lt;/span&gt;"
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
                DEFAULT  {
                    $template = $template.Replace( $key, $newval )
                }
            }
        }
    }

    return $template
}

# BUGBUG: Directly accesses $maxitems and $ctypenameid.
function BldQuery( [string] $action, [string] $jobname, [PSObject] $jobnode )  {

    $queryobj = [PSCustomObject]@{}

    # Start with default.
    if ( $jobname.Contains( "contenttype") )  {
        switch ( $action )  {
            "GET"  {
                $queryobj | Add-Member -Type NoteProperty -Name maxitems -Value $maxitems
            }
            # No query for POST, PUT, or DELETE.
        }
    }
    else  {
        switch ( $action )  {
            "GET"  {
                if ( $jobnode.ids.Length -eq 0 )  {
                    $queryobj | Add-Member -Type NoteProperty -Name contentTypeId -Value $ctypenameid[1]
                    $queryobj | Add-Member -Type NoteProperty -Name maxitems -Value $maxitems
                }
                # No query if content item IDs are specified.
            }
            "POST"  {
                $queryobj | Add-Member -Type NoteProperty -Name publish -Value "TRUE"
            }
            "PUT"  {
                $queryobj | Add-Member -Type NoteProperty -Name publish -Value "TRUE"
            }
            # No query for POST, PUT, or DELETE.
        }
    }

    # Replace with job values and add new ones, if any.
    if ( $jobnode.query -is [PSCustomObject] )  {
        $queryobj = ReplaceWithLegend $queryobj $jobnode.query $true
    }

    # Convert to string.
    $query = PSObj2Str $queryobj "&"
    if ( IsValid $query )   { return "?$query" }
    else                    { return "" }
}

function GetListOfIDs( [PSObject] $jobnode )  {
    if     ( $jobnode.ids -is [string] )  {  return @( $jobnode.ids )  }
    elseif ( $jobnode.ids -is [array] )   {  return $jobnode.ids  }
    else                                  {  return @()  }
}

function InvokeWebRequest( [string] $uri, [string] $action, [PSObject] $hdr, [string] $bodyjson )  {
    Write-Host "*** Query ($action) : $uri"

    if ( IsValid $bodyjson )  {
        Write-Host "*** Body : `n$bodyjson"
        $response = Invoke-WebRequest  -URI $uri  -Method $action  -ContentType $mimetype  -Headers $hdr  -Body $bodyjson
    }
    else  {
        $response = Invoke-WebRequest  -URI $uri  -Method $action  -ContentType $mimetype  -Headers $hdr
    }

    return $response
}

function MkPSObjKeyValPair( [PSObject] $respjsondocs )  {
    $outobj = [PSCustomObject]@{}
    $respjsondocs | foreach  {
        $k = $_.name.ToLower()
        $v = $_.id
        # If the key is not there yet, just add the key-value pair.
        if ( $outobj.psobject.properties.name -notcontains $k )  {
            $outobj | Add-Member -Type NoteProperty -Name $k -Value $v
        }
        # If the key is already there, add the new value to the array or create the array.
        else  {
            if ( $outobj.$k -is [array] )  { $outobj.$k += $v }
            else                           { $outobj.$k = @( $outobj.$k, $v ) }
        }
    }
    return $outobj
}



# MAIN -------------------------------------------------------

if ( $args.Count -gt 2 )  {
    $setsjson = $args[0]
    $jobname  = $args[1]
    $jsonpath = $args[2]

    $thisscript = $MyInvocation.MyCommand.Name
    $params = [string]::Join( " ", $args )

    $action = GetAction $jobname
    $apicall = GetAPICall $jobname
    $apicall = "/$apicall"
    $jobprefix = GetJobPrefix $jobname 2

    # Read the settings file.
    if (( IsNotValid $setsjson ) -or ( !( Test-Path $setsjson ) ))  {
        Write-Error "ERROR: Missing or invalid settings file."
        return
    }
    $mysettings = Get-Content -Raw -Path $setsjson | ConvertFrom-Json
    if ( IsValid $mysettings.apikey )          {  $apikey      = $mysettings.apikey  }
    if ( IsValid $mysettings.outraw )          {  $outraw      = $mysettings.outraw  }
    if ( IsValid $mysettings.contenttypeids )  {  $ctypeidlist = $mysettings.contenttypeids  }

    # $ctypenameid is a two-element array.
    $ctypenameid = GetContentTypeNameID $jobname $ctypeidlist

    # Compose the header.
    if ( $apikey -eq $NULL )  {
        Write-Error "ERROR: Null apikey setting in $setsjson."
        return
    }
    $hdr = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $hdr.Add( "Authorization", "Bearer " + $apikey )
    $hdr.Add( "Cache-Control", "no-cache, no-store, must-revalidate" )


    # Read the jobs file and the template file.
    Get-ChildItem -Path $jsonpath | Select-String -Pattern $jobname              | Group Path | Select Name | %{ $jobsjson = $_.name }
    Get-ChildItem -Path $jsonpath | Select-String -Pattern “TEMPLATE-$jobprefix” | Group Path | Select Name | %{ $tmpljson = $_.name }
    if ( !$tmpljson )  { $tmpljson = $jobsjson }
    $myjobs = Get-Content -Raw -Path $jobsjson | ConvertFrom-Json
    $mytmpl = Get-Content -Raw -Path $tmpljson | ConvertFrom-Json
    $jobnode = $myjobs.$jobname
    $permsarray = $jobnode.permutations


    # BODY
    # Start with the template, if any, then replace with job values, if any.
    if ( $jobnode -is [PSCustomObject] )  {

        $tmpljob = "TEMPLATE-$jobprefix"
        if ( $mytmpl.$tmpljob.body )  {
            $bodynode = $mytmpl.$tmpljob.body
            $bodynode = ReplaceWithLegend $bodynode $jobnode.body
        }
        else  {
            $bodynode = $jobnode.body
        }
    }
    else  {
        $bodynode = [PSObject]@{}
    }


    # BODY - CUSTOMIZATION

    # ContentTypes
    if ( $jobname.ToLower().Contains( "contenttype" ) )  {
        # Replace allowedContentTypeId in each field.
        $tmp = ReplaceRefsToOtherCTs $bodynode
        if ( $tmp )  { $bodynode = $tmp }
        else         { return }
    }

    # ContentItems
    else  {
        switch( $action )  {
            "POST"   {
                # FOR POSTS ONLY. Add the contentTypeID for the current job.
                if ( StrCompare $action "POST" )  {
                    $bodynode = CreateOrUpdateNode $bodynode "contentTypeID" $ctypenameid[1]
                }
            }
        }
    }

    # For tests only
    if ( IsValid $jobnode.testdesc )  {
        $testdesc = $jobnode.testdesc
        Write-Host "*** Job : $jobname - $testdesc"
    }


    # INVOKEWEBREQUEST

    $query = BldQuery $action $jobname $jobnode

    $responses = @()

    switch( $action )  {

        "GET"  {
            $IDList = GetListOfIDs $jobnode
            # Get specific object(s)
            if ( $IDList.Length -gt 0 )  {
                $IDList | foreach  {
                    $resp = InvokeWebRequest "$apiurl$apicall/$_$query" $action $hdr
                    if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                }
            }
            # Get object(s) based in filter in query.
            else  {
                    $resp = InvokeWebRequest "$apiurl$apicall$query" $action $hdr
                    if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
            }
        }

        "POST"   {
            if ( $permsarray.Length -gt 0 )  {
                foreach ( $perm in $permsarray )  {
                    $body = MkPerm $bodynode $perm
                    $resp = InvokeWebRequest "$apiurl$apicall$query" $action $hdr $body
                    if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                }
            }
            else  {
                $body = $bodynode | ConvertTo-Json -Depth 10
                $resp = InvokeWebRequest "$apiurl$apicall$query" $action $hdr $body
                if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
            }
        }

        "PUT"    {
            if ( $permsarray.Length -gt 0 )  {
                foreach ( $perm in $permsarray )  {
                    if ( IsValid $perm.id )  {
                        $id = "/" + $perm.id    # Each perm should include an ID.
                        $body = MkPerm $bodynode $perm
                        $resp = InvokeWebRequest "$apiurl$apicall$id$query" $action $hdr $body
                        if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                    }
                    # Don't do anything if there's no ID.
                }
            }
            else  {
                $IDList = GetListOfIDs $jobnode
                if ( $IDList.Length -gt 0 )  {
                    $IDList | foreach  {
                        $body = $bodynode | ConvertTo-Json -Depth 10
                        $resp = InvokeWebRequest "$apiurl$apicall/$_$query" $action $hdr $body
                        if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                    }
                }
                # Don't do anything if there's no ID.
            }
        }

        "DELETE"  {
            $IDList = GetListOfIDs $jobnode
            if ( $IDList.Length -gt 0 )  {
                $IDList | foreach  {
                    $resp = InvokeWebRequest "$apiurl$apicall/$_$query" $action $hdr
                    if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                }
            }
            # Don't do anything if there's no ID.
        }

        "GET-DELETE"  {
            # Overwrite query for GET-DELETE.
            $query = BldQuery "GET" $jobname $jobnode

            $getresponse = InvokeWebRequest "$apiurl$apicall$query" "GET" $hdr
            if ( $getresponse )  {
                $respjson = $getresponse | ConvertFrom-Json
                $IDList = @()
                $respjson.documents | foreach  {
                    # 1. Compare the content type name, in case the content type ID was not passed to InvokeWebRequest.
                    # 2. Do not delete system/default content types and content items.
                    if ( ( StrCompare $_.contentTypeName $ctypenameid[0] ) -and !($_.isSystem) )  {
                        $IDList += $_.id
                    }
                }
                if ( $IDList.Length -gt 0 )  {
                    $query = BldQuery "DELETE" $jobname $jobnode
                    $IDList | foreach  {
                        $resp = InvokeWebRequest "$apiurl$apicall/$_$query" "DELETE" $hdr
                        if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                    }
                }
            }
        }

    }


    # RESULTS

    ## raw
    if ( IsValid $outraw )  {
        foreach ( $resp in $responses )  {
            Write-Output $resp | Out-File $outraw -Encoding DEFAULT
        }
    }

    ## With list-* jobs, update the list of ids in $setsjson and display in console.
    if ( $jobname.StartsWith( "list-" ) )  {
        $idsnodename = $ctypenameid[0] + "ids"
        foreach ( $resp in $responses )  {
            $respjson = $resp | ConvertFrom-Json
            $newids = MkPSObjKeyValPair $respjson.documents
            $mysettings = CreateOrUpdateNode $mysettings $idsnodename "" $newids
        }
        $mysettings | ConvertTo-Json -Depth 10 | Out-File $setsjson -Encoding DEFAULT
        $mysettings.$idsnodename | Out-Host
    }

}
else  {
    Usage
}


# ============================================================
