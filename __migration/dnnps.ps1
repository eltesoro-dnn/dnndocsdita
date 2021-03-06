# ============================================================
# Performs GET, POST, PUT, DELETE against the DNN APIs.
#
# Resources:
# https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.utility/invoke-webrequest
# ============================================================


# GLOBAL VARIABLES -------------------------------------------

$apiurl = "https://dnnapi.com/content/api"
$mimetype = "application/json"
$maxitems = 100

$lt = "\u003c"
$gt = "\u003e"

# $APICALLS = @( "ContentTypes", "ContentItems" )
# $ACTIONS  = @( "GET", "POST", "PUT", "DELETE" )


# FUNCTIONS --------------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script $setsjson $assetstxt $jobsjson $jobname"


    $examples = @(
        "powershell -file $script settings.json json\assets.txt jobs-sections.json listall-contenttypes"
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


function IsContentType( [string] $jobname )  {
    $arr = $jobname.Split( "-_", [System.StringSplitOptions]::RemoveEmptyEntries )
    if ( $arr.Length -lt 2 )                              {  return $false  }
    if ( $arr[1].ToLower().StartsWith( "contenttype" ) )  {  return $true  }
    else                                                  {  return $false  }
}
function GetContentTypeName( [string] $jobname )  {
    $arr = $jobname.Split( "-", [System.StringSplitOptions]::RemoveEmptyEntries )
    if ( $arr.Length -gt 1 )  {  return $arr[1]  }
    else                      {  return ""  }
}
# BUGBUG: Accesses the $global:ctypeidlist var directly.
# $ctypename must be singular to match the names in $global:ctypeidlist.
function GetContentTypeID( [string] $ctypename )  {
    if ( $global:ctypeidlist.$ctypename )  {  return $global:ctypeidlist.$ctypename  }
    else                            {  return ""  }
}
# Gets the contenttype ID from the settings file, based on the contenttype embedded in the jobname.
function GetContentTypeNameID( [string] $jobname )  {
    $arr = @()
    $jobctname = GetContentTypeName $jobname
    if ( $jobctname.Contains( "contenttype" ) )  {
        $arr = @( "contenttype", "" )
    }
    else  {
        foreach ( $name in $global:ctypeidlist.psobject.properties.name )   {
            $namelc = "-" + $name.ToLower()
            if ( $jobname.ToLower().Contains( $namelc ) )  {
                $arr = @( $name, $global:ctypeidlist.$name )
            }
        }
    }
    return $arr
}

# Gets the contentitem ID from the settings file, based on the contenttype and the contentitem name.
function GetContentItemID( [string] $contentitemname )  {
    foreach ( $ctype in $global:mysettings.psobject.properties.name )  {
        $ctypenode = $global:mysettings.$ctype
        if ( $ctypenode.$contentitemname -is [string] )  { return $ctypenode.$contentitemname }
        if ( $ctypenode.$contentitemname -is [array] )   { return $ctypenode.$contentitemname[0] }
    }
    return ""
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

function GetAction( [string] $jobname )  {
    if ( $jobname.StartsWith( "list-"      ) )  { return "GET" }
    if ( $jobname.StartsWith( "listall-"   ) )  { return "GET" }
    if ( $jobname.StartsWith( "add-"       ) )  { return "POST" }
    if ( $jobname.StartsWith( "update-"    ) )  { return "PUT" }
    if ( $jobname.StartsWith( "delete-"    ) )  { return "DELETE" }
    if ( $jobname.StartsWith( "deleteall-" ) )  { return "GET-DELETE" }
}

function GetAPICall( [string] $jobname )  {
    if ( IsContentType $jobname )  { return "ContentTypes" }
    else                           { return "ContentItems" }
}

function GetJobPrefix( [string] $jobname, [int32] $count )  {
    $arr = $jobname.Split( "-_", [System.StringSplitOptions]::RemoveEmptyEntries )
    $i = $count - 1
    return [string]::Join( "-", $arr[0..$i] )
}

# If the key already exists, updates the value of an existing key; otherwise, creates a new key-value pair.
function CreateOrUpdateNode( [PSObject] $parent, [string] $key, [string] $valstr, [PSObject] $valobj )  {
    if     ( IsValid $valstr )  { $value = $valstr }
    elseif ( IsValid $valobj )  { $value = $valobj }
    else                        { $value = "" }

    if ( IsValid $value )  {
        if ( $parent.psobject.properties.name -contains $key )  {
            $parent.$key = $value
        }
        else {
            $parent | Add-Member -Type NoteProperty -Name $key -Value $value
        }
    }
    else  {
        $parent = $parent | Select-Object -Property * -ExcludeProperty $key
    }

    return $parent
}

# For content types only. If $bodynode.fields includes references to another contenttype, check if that contenttype already exists. If it exists, get its ID; otherwise, error message.
function ReplaceRefsToOtherCTs( [PSObject] $bodynode )  {
    #  Get IDs of referenced contenttypes from the site settings.
    $bodynode.fields | foreach  {
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
    return $bodynode
}

#Wraps one string inside <span/> tags with the specified class
function WrapSpanStr( [string] $text, [string] $class )  {
    $wrap = "span"
    return "$lt$wrap class=$class$gt$text$lt/$wrap$gt"
}
# Wraps each element of an array inside <span/> tags with the specified class.
function WrapSpanElements( [string[]] $arr, [string] $class )  {
    $new = @()
    $arr | foreach  {
        $new = WrapSpanStr $_ $class
    }
    return $new
}
function ReplaceTagWithSpan( [string] $text, [string] $tag )  {
    $wrap = "span"
    return $text.Replace( "$lt$tag$gt", "$lt$wrap class=$tag$gt" ).Replace( "$lt/$tag$gt", "$lt/$wrap$gt" )
}
# Returns one permutation.
function MkPerm( [PSObject] $freshbody, [PSObject] $perm, [array] $assetsarr )  {
    $ignorearr = @( "id" )

    # Do not copy keys that are not in the target $freshbody (_*_ keys).
    $freshbody = ReplaceWithLegend $freshbody $perm $false

    # Convert to string for easier replacements of the _*_ keys.
    $bodyjson = $freshbody | ConvertTo-Json -Depth 10

    # Replace the _*_ vars.
    foreach ( $key in $perm.psobject.properties.name ) {
        if (( $ignorearr -notcontains $key ) -and ( $key.StartsWith( "_" ) ))  {

            if ( $perm.$key -is [array] )  {
                $newval = @( $perm.$key )
            }
            else  {
                $newval = $perm.$key
            }

            $arr = $key.Split( "-_", [System.StringSplitOptions]::RemoveEmptyEntries )
            $keystart = $arr[0]

            switch ( $keystart )  {
                "id"  {
                    # Get the ID of the referenced content item.
                    # Example: "_id-ctype-foo_" = "nameofmycontentitem" will get the ID of the content item "nameofmycontentitem" of type "ctype".
                    # NOTE: ctype must be singular.
                    $newval = GetContentItemID $newval
                    if ( !$newval )  {
                        Write-Error "WARNING: Content item ID for $key not found."
                    }
                    else  {
                        $bodyjson = $bodyjson.Replace( $key, $newval )
                    }
                    break;
                }
                "dashed"  {
                    if ( $newval -is [array] )  {
                        $newval = [string]::Join( "-", $newval )
                    }
                    $newval = $newval.Replace( " ", "" ).Replace( "/", "" ).ToLower()
                    $bodyjson = $bodyjson.Replace( $key, $newval )
                    break;
                }
                "menucasc"  {
                    if ( $newval -is [array] )  {
                        $arr = WrapSpanElements $newval "ph uicontrol"
                        $newval = "&lt;span class=&quot;menucascade&quot;&gt;" + [string]::Join( " &gt; ", $arr ) + "&lt;/span&gt;"
                    }
                    $bodyjson = $bodyjson.Replace( $key, $newval )
                    break;
                }
                "menualt"  {
                    if ( $newval -is [array] )  {
                        $newval = [string]::Join( " &gt; ", $newval )
                    }
                    $bodyjson = $bodyjson.Replace( $key, $newval )
                    break;
                }
                "unixdate"  {
                    $newval = GetUnixDate( $newval )

                    $bodyjson = $bodyjson.Replace( $key, $newval )
                    $bodyjson = $bodyjson.Replace( """$key""", $newval )
                    break;
                }
                "int"  {
                    $bodyjson = $bodyjson.Replace( $key, $newval )
                    $bodyjson = $bodyjson.Replace( """$key""", $newval )
                    break;
                }
                "arr2str"  {
                    if ( $newval -is [array] )  {
                        $newval = [string]::Join( "\r\n", $newval.Replace( "\u003c", "<" ).Replace( "\u003e", ">" ) )
                    }
                    break;
                }
                DEFAULT  {
                    $bodyjson = $bodyjson.Replace( $key, $newval )
                }
            }
        }
    }

    # Convert to PSObject to get the filename after replacements.
    $freshbody = $bodyjson | ConvertFrom-Json
    if ( $freshbody.details.imageFile.Count -gt 0 )  {
        $imgfn = $freshbody.details.imageFile[0].fileName
        if ( IsValid $imgfn )  {
            $imgfn = $imgfn.ToLower()
            $assetsarr | foreach  {
                if ( $_.ToLower().Contains( $imgfn ) )  {
                    $bodyjson = $bodyjson.Replace( "_imgurl_", $_ )
                }
            }
        }
    }

    return $bodyjson
}
function ReplaceDitaTags( [string] $template )  {
    # Tag becomes class.
    @( "uicontrol" ) | foreach {
        $template = ReplaceTagWithSpan $template $_
    }
    return $template
}

# BUGBUG: Directly accesses $maxitems.
function BldQuery( [string] $action, [string] $jobname, [PSObject] $jobnode, [string] $ctypeid )  {

    $queryobj = [PSCustomObject]@{}

    # Start with default.
    if ( IsContentType $jobname )  {
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
                    $queryobj | Add-Member -Type NoteProperty -Name contentTypeId -Value $ctypeid
                    $queryobj | Add-Member -Type NoteProperty -Name maxitems -Value $maxitems
                }
                # No query if content item IDs are specified.
                break;
            }
            "POST"  {
                $queryobj | Add-Member -Type NoteProperty -Name publish -Value "TRUE"
                break;
            }
            "PUT"  {
                $queryobj | Add-Member -Type NoteProperty -Name publish -Value "TRUE"
                break;
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

# Do not include system/default content types and content items.
function GetListOfIDsFromResponse( [PSObject] $respjsondocs, [string] $jobname )  {
    $isCT = IsContentType $jobname
    $IDList = @()

    # Content items: Confirm the content type name, in case the content type ID was not passed to InvokeWebRequest and it returned ALL content items.
    if ( !$isCT )  {
        $respjsondocs | foreach  {
            if ( $ctypenameid -and ( StrCompare $_.contentTypeName $ctypenameid[0] ) )  {
                $IDList += $_.id
            }
        }
    }

    # Content types: Sort from not-depended-on to depended-on (with fields that have allowedContentTypeId).
    else  {
        # Get the IDs, sorted by dependencies.
        $respjsondocs | foreach  {
            # If the current type is not already in the list, add it to the top.
            if ( $IDList -notcontains $_.id )  {
                $IDList = @($_.id) + $IDList
            }
            # Check if each reference is already in the list. If not, add to the bottom.
            foreach ( $fld in $_.fields )  {
                $allowedCT = $fld.allowedContentTypeId
                if ( $allowedCT -and ( $IDList -notcontains $allowedCT ) )  {
                    $IDList += $allowedCT
                }
            }
        }

        # Remove the system/default content types.
        $respjsondocs | foreach  {
            if ( $_.isSystem )  { $IDList = $IDList -ne $_.id }
        }
    }

    return $IDList
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

function RobocopyBasic( [string] $src, [string] $tgt, [string] $opts )  {
    Write-Host "Copying from $src to $tgt with options $opts ...."
    $cmd = "@robocopy " + $src + " " + $tgt + " /mt /log+:" + $copylog + " " + $opts
    RunBat $cmd
}


# MAIN -------------------------------------------------------

if ( $args.Count -gt 2 )  {
    $jobname  = $args[0]
    $jsonpath = $args[1]
    $setsjson = $args[2]
    $assettxt = $args[3]

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
    $global:mysettings = Get-Content -Raw -Path $setsjson | ConvertFrom-Json
    if ( IsValid $global:mysettings.apikey )          {  $apikey             = $global:mysettings.apikey  }
    if ( IsValid $global:mysettings.contenttypeids )  {  $global:ctypeidlist = $global:mysettings.contenttypeids  }

    $assets = Get-Content $assettxt

    # $ctypenameid is a two-element array.
    $ctypenameid = GetContentTypeNameID $jobname

    if ( IsValid $global:mysettings.outraw )  {
        $outraw = $global:mysettings.outraw
        if ( $ctypenameid )  {
            $outraw = $ctypenameid[0] + "-" + $outraw
        }
    }


    # Compose the header.
    if ( $apikey -eq $NULL )  {
        Write-Error "ERROR: Null apikey setting in $setsjson."
        return
    }
    $hdr = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $hdr.Add( "Authorization", "Bearer " + $apikey )
    $hdr.Add( "Cache-Control", "no-cache, no-store, must-revalidate" )


    # Read the jobs file and the template file.
    Get-ChildItem -Path $jsonpath | Select-String -Pattern """$jobname"""      | Group Path | Select Name | %{ $jobsjson = $_.name }
    Get-ChildItem -Path $jsonpath | Select-String -Pattern """TEMPLATE-$jobname""" | Group Path | Select Name | %{ $tmpljson = $_.name }
    if ( !$tmpljson )  { Get-ChildItem -Path $jsonpath | Select-String -Pattern """TEMPLATE-$jobprefix""" | Group Path | Select Name | %{ $tmpljson = $_.name } }
    if ( !$tmpljson )  { $tmpljson = $jobsjson }

    if ( $jobsjson )  {  $myjobs = Get-Content -Raw -Path $jobsjson | ConvertFrom-Json  }
    else  { Write-Error "ERROR: jobsjson is null."; return }
    if ( $tmpljson )  {  $mytmpl = Get-Content -Raw -Path $tmpljson | ConvertFrom-Json  }
    else  { Write-Error "ERROR: tmpljson is null." }

    $jobnode  = $myjobs.$jobname
    $permsarray = $myjobs.$jobname.permutations

    $tmplnode = $null
    @( "TEMPLATE-$jobprefix", "TEMPLATE-$jobname" ) | foreach {
        if ( $mytmpl.$_.body )  {  $tmplnode = $mytmpl.$_  }
    }

    # BODY
    # Copy the template, if any, then replace with job values, if any.
    if ( $tmplnode.body -is [PSObject] )  {
        $bodynode = $tmplnode.body.psobject.Copy()
        $bodynode = ReplaceWithLegend $bodynode $jobnode.body
    }
    elseif ( $jobnode.body -is [PSObject] )  {
        $bodynode = $jobnode.body.psobject.Copy()
    }
    else  {
        $bodynode = [PSCustomObject]@{}
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
                    $bodynode = CreateOrUpdateNode $bodynode "contentTypeID" $ctypenameid[1] $null
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

    if ( $ctypenameid )  {
        $query = BldQuery $action $jobname $jobnode $ctypenameid[1]
    }
    else  {
        $query = BldQuery $action $jobname $jobnode ""
    }

    $responses = @()

    # This will be used as the clean customized copy of $bodynode.
    $basebodyjson = $bodynode | ConvertTo-Json -Depth 10

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
            break;
        }

        "POST"  {
            if ( $permsarray.Length -gt 0 )  {
                foreach ( $perm in $permsarray )  {
                    $bodynode = $basebodyjson | ConvertFrom-Json
                    $body = MkPerm $bodynode $perm $assets
                    $body = ReplaceDitaTags $body
                    $resp = InvokeWebRequest "$apiurl$apicall$query" $action $hdr $body
                    if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                }
            }
            else  {
                $bodynode = $basebodyjson | ConvertFrom-Json
                $body = $bodynode | ConvertTo-Json -Depth 10
                $body = ReplaceDitaTags $body
                $resp = InvokeWebRequest "$apiurl$apicall$query" $action $hdr $body
                if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
            }
            break;
        }

        "PUT"  {
            if ( $permsarray.Length -gt 0 )  {
                foreach ( $perm in $permsarray )  {
                    if ( IsValid $perm.id )  {
                        $id = "/" + $perm.id    # Each perm should include an ID.
                        $bodynode = $basebodyjson | ConvertFrom-Json
                        $body = MkPerm $bodynode $perm $assets
                        $body = ReplaceDitaTags $body
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
                        $bodynode = $basebodyjson | ConvertFrom-Json
                        $body = $bodynode | ConvertTo-Json -Depth 10
                        $body = ReplaceDitaTags $body
                        $resp = InvokeWebRequest "$apiurl$apicall/$_$query" $action $hdr $body
                        if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                    }
                }
                # Don't do anything if there's no ID.
            }
            break;
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
            break;
        }

        "GET-DELETE"  {
            # Overwrite query for GET-DELETE.
            $query = BldQuery "GET" $jobname $jobnode

            # Create the list of content type/item IDs to delete.
            $getresponse = InvokeWebRequest "$apiurl$apicall$query" "GET" $hdr
            if ( $getresponse )  {
                $respjson = $getresponse | ConvertFrom-Json
                $IDList = GetListOfIDsFromResponse $respjson.documents $jobname

                if ( $IDList.Length -gt 0 )  {
                    $query = BldQuery "DELETE" $jobname $jobnode
                    $IDList | foreach  {
                        $resp = InvokeWebRequest "$apiurl$apicall/$_$query" "DELETE" $hdr
                        if ( $resp.content )  {  $responses += ($resp.content).Replace( "  ", "    " )  }
                    }
                }
            }
            break;
        }

    }


    # RESULTS

    ## raw
    if ( IsValid $outraw )  {
        Write-Output $responses | Out-File $outraw -Encoding DEFAULT
        # foreach ( $resp in $responses )  {
        #     Write-Output $resp | Out-File $outraw -Encoding DEFAULT
        # }
    }

    ## With listall-* jobs, update the list of ids in $setsjson and display in console.
    if ( $jobname.StartsWith( "listall-" ) )  {
        if ( $jobname.StartsWith( "listall-contenttypes" ) )  {
            $idsnodename = "contenttypeids"
        }
        elseif ( $ctypenameid )  {
            $idsnodename = $ctypenameid[0] + "ids"
        }
        else  {
            $idsnodename = "ids"
        }

        foreach ( $resp in $responses )  {
            $respjson = $resp | ConvertFrom-Json
            $newids = MkPSObjKeyValPair $respjson.documents
            $global:mysettings = CreateOrUpdateNode $global:mysettings $idsnodename "" $newids
        }

        $global:mysettings | ConvertTo-Json -Depth 10 | Out-File $setsjson -Encoding DEFAULT
        $global:mysettings.$idsnodename | Out-Host
    }

}
else  {
    Usage
}


# ============================================================
