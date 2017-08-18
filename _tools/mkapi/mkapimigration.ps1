# ======================================================================
# Converts swagger.json into permutations for the jobs-webapi*.json files for the DocCenter migration to Evoq.
#
# Source (swagger.json):
#     * paths, which contains
#         ** /api/*, which contain
#             *** actions (GET, POST, PUT, DELETE), which contain
#                 *** tags
#                 *** summary
#                 *** parameters, each of which contains
#                     **** name
#                     **** in
#                     **** description
#                     **** required
#                     **** type
#                     **** (if no type) schema.$ref to a DTO definition
#                 *** responses, each of which contains
#                     **** code
#                     **** schema.$ref to a DTO definition
#                 *** security, which contains
#                     **** oauth2, which contains
#                         ***** sc-api-key:???
#     * definitions, which contains
#         ** StructuredContent.API.Dto.*, which contain
#             *** description
#             *** type
#             *** properties, each of which contains
#                 **** description
#                 **** type
#                 **** format
#                 **** (if no type) $ref
#
# Targets:
#     * jobs-webapimethods.json
#     * jobs-webapisections.json
#     * jobs-webapiparams.json
#     * jobs-webapidtos.json
#     * jobs-webapifields.json
#
#     Each webapimethod requires:
#         * name
#         * summary
#         * action (GET, POST, PUT, DELETE)
#         * uRLSection (webapisection)
#         * messageSection (webapisection)
#         * resultsSection (webapisection)
#         * remarks (passage)
#         * relatedLinks
#     Each webapisection requires:
#         * name
#         * responseCode
#         * sectionDescription
#         * syntax
#         * pathParams (webapiparams)
#         * mainParams (webapiparams)
#     Each webapiparam requires:
#         * name
#         * paramName
#         * in
#         * requiredOptional
#         * field (webapifield)
#         * dTO (webapidto)
#     Each webapidto requires:
#         * name
#         * dTODesc
#         * syntax
#         * fields (webapifield)
#     Each  webapifield requires:
#         * name
#         * fieldName
#         * dataType
#         * enumList
#         * fieldDesc
#
# Implementation:
#     * Only specific APIs need to be in the DocCenter.
#     * In each API and for each action,
#         ** If the parameter has "type", create a webapifield and a matching webapiparam.
#         ** If the parameter has "schema.$ref", create a webapidto and a matching webapiparam.
#         ** Create the URL section, the message section, and the results section. Use the webapiparams, not the fields or DTOs.
#         ** Create the webapimethod.
#         ** Create the jobs*.json files.
#
# ======================================================================


# GLOBAL VARIABLES -------------------------------------------

$apiurl = "https://dnnapi.com/content"

$apitypes = @(
    "/api/ContentTypes"
    ,"/api/ContentTypes/{id}"
    ,"/api/ContentTypes/name/{name}"
    ,"/api/ContentItems"
    ,"/api/ContentItems/{id}"
    ,"/api/PublishedContentItems/GetByIds"
    ,"/api/PublishedContentItems"

    # ,"/api/ApiKeys/{id}/Reset"
    # ,"/api/ApiKeys"
    # ,"/api/ApiKeys/{id}"
    # ,"/api/ContentItemAnalytics/GetSharedUrls"
    # ,"/api/ContentItemAnalytics/{id}"
    # ,"/api/ContentItems/{id}/availableLocalizations"
    # ,"/api/ContentItems/{id}/usages"
    # ,"/api/ContentItems/referenceobjects/{contentItemId}"
    # ,"/api/ContentItems/ClientReferenceId/{clientReferenceId}"
    # ,"/api/EmbedVisualizerInstances"
    # ,"/api/ImportExport/export"
    # ,"/api/ImportExport/import"
    # ,"/api/ImportExport/checkImport"
    # ,"/api/ImportExport/checkExport"
    # ,"/api/Languages/enabled"
    # ,"/api/management/CopyTenant"
    # ,"/api/Revisions/{contentItemId}"
    # ,"/api/Revisions/{contentItemId}/{version}"
    # ,"/api/Revisions/referenceobjects/{contentItemId}/{version}"
    # ,"/api/Tags"
    # ,"/api/Version"
    # ,"/api/VisualizerEngine/Preview"
    # ,"/api/VisualizerEngine/Render"
    # ,"/api/VisualizerEngine/RenderList"
    # ,"/api/VisualizerEngine/RenderDetail"
    # ,"/api/VisualizerEngine/RenderRelatedContent"
    # ,"/api/VisualizerEngine/RenderDetailBatch"
    # ,"/api/VisualizerInstances/{id}"
    # ,"/api/VisualizerInstances"
    # ,"/api/Visualizers/name/{name}"
    # ,"/api/Visualizers/export/{id}"
    # ,"/api/Visualizers/import"
    # ,"/api/Visualizers"
    # ,"/api/Visualizers/{id}"
    # ,"/api/WebHooks"
)
$methods = @( "get", "post", "put", "delete" )

# Permutations to put in the output files
$global:permsfields   = @()
$global:permsdtos     = @()
$global:permsparams   = @()
$global:permssections = @()
$global:permsmethods  = @()

# Lists of permutation names (to check if already existing for reuse)
$global:listfields   = @()
$global:listdtos     = @()
$global:listparams   = @()
$global:listsections = @()
$global:listmethods  = @()

# Definitions node - Must be global for functions to access directly.
$global:defsnode = $null


# GENERAL FUNCTIONS ------------------------------------------

function Usage()  {
    $script = $MyInvocation.ScriptName
    $usage = "powershell -file $script SwaggerURL swagger.json outdir`r`n`t*** IMPORTANT: Run with params, then run dnnps to refresh the IDs, then run with methods."
    $examples = @(
        "powershell -file $script www.example.com/swagger json\swagger.json out"
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

# Reference: https://blogs.technet.microsoft.com/heyscriptingguy/2011/05/10/use-the-pipeline-to-create-robust-powershell-functions/
function PrettifyJson  {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)] [string[]] $pipedjson
    )

    PROCESS {
        $tabs = ""
        $outstr = ""
        $arr = $input -split "`r`n"
        $newarr = @()
        foreach ( $ln in $arr )  {
            # do stuff here with $ln
            $lntrim = $ln.Trim().Replace( "\u003c", "<" ).Replace( "\u003e", ">" )
            if (( $lntrim.StartsWith( "]" ) ) -or ( $lntrim.StartsWith( "}" ) ))  {
                $tabs = $tabs -replace "    \Z"
            }
            if ( IsValid $lntrim )   { $newarr += "$tabs$lntrim" }
            if (( $lntrim.EndsWith( "[" ) )   -or ( $lntrim.EndsWith( "{" ) ))    {
                $tabs += "    "
            }
        }
        $joined = $newarr -join "`r`n"
        Write-Output $joined
    }
}


# NOTE: "_id-$name_" seems to chop off anything after "_id-", so the pieces have to be concatenated into the $marker variable.
# $value can be any type.
function AddKeyValue( [PSObject] $node, [string] $key, $value )  {
    $node | Add-Member -Type NoteProperty -Name $key -Value $value
    return $node
}
# # If the actual value is an ID that dnnps.ps1 needs to look up from the settings file.
# # Do not use for references, even if single reference. Reference fields always expect an array.
# function AddKeyID( [PSObject] $node, [string] $key, [string] $name )  {
#     $marker = "_id-" + $name.ToLower().Replace( " ", "" ) + "_"
#     $node = AddKeyValue $node $key $marker
#     $node = AddKeyValue $node $marker $name
#     return $node
# }
# Adds a list of fields whose IDs need to be looked up.
function AddKeyIDList( [PSObject] $node, [string] $key, [string[]] $namesarr )  {
    $markerlist = @()
    if ( $namearr -is [string] )  { $namesarr = @( $namesarr ) }
    foreach ( $name in $namesarr ) {
        if ( IsValid $name )  {
            $marker = "_id-" + $name.ToLower().Replace( " ", "" ) + "_"
            $node = AddKeyValue $node $marker $name
            $markerlist += $marker
        }
    }
    $node = AddKeyValue $node $key $markerlist
    return $node
}

# Example API name: "/api/ContentItems/{id}"
# To combine into a single word, use $_.Replace( " ", "" )
# To make plural (BUGBUG), use $_ + "s"
# To change case, use $_.ToUpper() or $_.ToLower
function GetAPIGroup( [string] $name )  {
    if ( $name.ToLower().Contains( "contenttypes" ) )           { return "Content Type" }
    if ( $name.ToLower().Contains( "publishedcontentitems" ) )  { return "Published Content Item" }
    if ( $name.ToLower().Contains( "contentitems" ) )           { return "Content Item" }
    return ""
}

function FlattenName( [string] $name )  {
    $arr = $name.ToLower().Split( "./\{\}\[\] ", [System.StringSplitOptions]::RemoveEmptyEntries )
    return [string]::Join( "", $arr )
}

# MkName $type $apigroup $action $name
# MkName $type $name
function MkName( [string] $type, [string] $thing, [string] $action, [string] $name )  {
    $arr = @()
    if ( $thing )   { $arr += FlattenName $thing }
    if ( $action )  { $arr += FlattenName $action }
    if ( $name )    { $arr += FlattenName $name }
    $joined = [string]::Join( "-", $arr )
    return "api$type-$joined"
}

function GetPermNode( [PSObject[]] $nodearr, [string] $nodename )  {
    $nodearr | foreach {
        if ( StrCompare $_.name $nodename )  { return $_ }
    }
    return $null
}

# WARNING: Accesse global variables directly.
function MkFieldNode( [PSObject] $paramnode, [string] $thing, [string] $action, [string] $defname )  {
    # Write-Host "DEBUG: MkFieldNode *** "
    if     ( IsValid $paramnode.name )  { $name = MkName "field" $thing $action $paramnode.name }   # for regular parameters
    elseif ( IsValid $defname )         { $name = MkName "field" $thing $action $defname }          # for dto properties

    if ( $global:listfields -notcontains $name )  {
        $newnode = [PSCustomObject]@{}
        $newnode = AddKeyValue $newnode "name" $name

        # fieldName
        if     ( IsValid $paramnode.name )  { $newnode = AddKeyValue $newnode "fieldName" $paramnode.name }  # for regular parameters
        elseif ( IsValid $defname )         { $newnode = AddKeyValue $newnode "fieldName" $defname }         # for dto properties

        # dataType
        if ( $paramnode.'type' )  {
            $type = $paramnode.'type'
            if ( $paramnode.format )  {
                $type = "$type-" + ($paramnode.format).Replace( " ", "-" )
            }
            $newnode = AddKeyValue $newnode "dataType" $type
        }
        else  {
            if ( $paramnode.'$ref' )  {
                $newnode = AddKeyValue $newnode "dataType" "object"

                # Determine the subtype (if any) to add to the description below.
                $subtype = GetRefName $paramnode.'$ref'
                switch ( $subtype )  {
                    "StructuredContent.Models.UserInfo"                     { $subtype = "Person" }
                    "StructuredContent.Models.SeoSettings"                  { $subtype = "SEO Settings" }
                    "StructuredContent.API.Dto.ContentItems.ContentItem"    { $subtype = "Content Item" }
                }
            }
        }

        # enumList
        if ( $paramnode.enum )    { $newnode = AddKeyValue $newnode "enumList"  $paramnode.enum }

        # elementType (if type is array)
        if ( $paramnode.items )  {
            $items = GetRefName $paramnode.items.'$ref'
            $newnode = AddKeyValue $newnode "elementType" $items
        }

        # fieldDesc
        $desc = MkFieldDesc $thing $action $paramnode.name $paramnode.description
        if ( IsValid $desc )  {
            if ( IsValid $subtype )  { $desc = "[$subtype] " + $desc }
            $newnode = AddKeyValue $newnode "fieldDesc" $desc
        }

        $global:permsfields += $newnode
        $global:listfields  += $newnode.name

        return $newnode
    }
    else  {
        $oldnode = GetPermNode $global:permsfields $name
        return $oldnode
    }
}
# WARNING: Accesse global variables directly.
function MkDtoNode( [string] $defname, [string] $thing, [string] $action )  {
    # Write-Host "DEBUG: MkDtoNode *** "
    $defnode = GetRefNode $defname
    $name = MkName "dto" $thing $action $defname

    if ( $global:listdtos -notcontains $name )  {
        $newnode = [PSCustomObject]@{}
        $newnode = AddKeyValue $newnode "name" $name

        # dTODesc
        $desc = MkFieldDesc $thing $action $defname $defnode.description
        if ( IsValid $desc )  { $newnode = AddKeyValue $newnode "dTODesc" $desc }

        # syntax
        $syntax = GetRefSyntax $defname
        if ( IsValid $syntax )  {
            $syntaxstr = $syntax | ConvertTo-Json -Depth 100 | PrettifyJson
            $newnode = AddKeyValue $newnode "syntax" $syntaxstr
        }

        # fields
        $proplist = @()
        foreach ( $propname in $defnode.'properties'.psobject.properties.name )  {
            $newfieldnode = MkFieldNode $defnode.'properties'.$propname $thing "dto" $propname
            $proplist += $newfieldnode.name
        }
        if ( $proplist.Count -gt 0 )  { $newnode = AddKeyIDList $newnode "fields" $proplist }

        $global:permsdtos += $newnode
        $global:listdtos  += $newnode.name

        return $newnode
    }
    else  {
        $oldnode = GetPermNode $global:permsdtos $name
        return $oldnode
    }
}

function MkSectionNodeUrl( [PSObject] $actionnode, [string] $apiname, [string] $thing, [string] $action, [string[]] $pathparams, [string[]] $queryparams )  {
    # Write-Host "DEBUG: MkSectionNodeUrl *** "
    $name = MkName "section-url" $apiname

    if ( $global:listsections -notcontains $name )  {
        $newnode = [PSCustomObject]@{}
        $newnode = AddKeyValue $newnode "name" $name

        switch ( $action.ToLower() )  {
            "get"     { $desc = "The URI with the criteria (ID or query) for the requested $apigroup." }
            "post"    { $desc = "The URI to create the new $apigroup." }
            "put"     { $desc = "The URI with the ID of the $apigroup to update." }
            "delete"  { $desc = "The URI with the ID of the $apigroup to delete." }
            default { $desc = "" }
        }
        if ( IsValid $desc )  { $newnode = AddKeyValue $newnode "sectionDescription" $desc }

        $syntax = MkURL $apiname $queryparams
        if ( IsValid $syntax )  { $newnode = AddKeyValue $newnode "syntax" $syntax }

        if ( $pathparams.Count  -gt 0 )  { $newnode = AddKeyIDList $newnode "pathParams" $pathparams }
        if ( $queryparams.Count -gt 0 )  { $newnode = AddKeyIDList $newnode "mainParams" $queryparams }

        $global:permssections += $newnode
        $global:listsections  += $newnode.name

        return $newnode
    }
    else  {
        $oldnode = GetPermNode $global:permssections $name
        return $oldnode
    }
}
function MkSectionNodeBody( [PSObject] $actionnode, [string] $apiname, [string] $thing, [string] $action, [string[]] $bodyparams )  {
    # Write-Host "DEBUG: MkSectionNodeBody *** ... bodyparams is $bodyparams"
    $name = MkName "section-body" $apiname

    if ( $global:listsections -notcontains $name )  {
        $newnode = [PSCustomObject]@{}
        $newnode = AddKeyValue $newnode "name" $name

        switch ( $action.ToLower() )  {
            "post"    { $desc = "The settings for the new $thing to create." }
            "put"     { $desc = "The new settings for the $thing to update." }
            default { $desc = "" }
        }
        if ( IsValid $desc )  { $newnode = AddKeyValue $newnode "sectionDescription" $desc }

        $syntax = MkSyntax $actionnode "body"
        if ( IsValid $syntax )  {
            $syntaxstr = $syntax | ConvertTo-Json -Depth 100 | PrettifyJson
            $newnode = AddKeyValue $newnode "syntax" $syntaxstr
        }

        if ( $bodyparams.Count -gt 0 )  { $newnode = AddKeyIDList $newnode "mainParams" $bodyparams }

        $global:permssections += $newnode
        $global:listsections  += $newnode.name

        return $newnode
    }
    else  {
        $oldnode = GetPermNode $global:permssections $name
        return $oldnode
    }
}
function MkSectionNodeResponse( [string] $code, [PSObject] $codenode, [string] $apiname, [string] $thing, [string] $action )  {
    # Write-Host "DEBUG: MkSectionNodeResponse *** "
    $name = MkName "section-response" $apiname $action $code

    if ( $global:listsections -notcontains $name )  {
        $newnode = [PSCustomObject]@{}
        $newnode = AddKeyValue $newnode "name" $name

        if ( IsValid $code )  { $newnode = AddKeyValue $newnode "responseCode" $code }

        switch ( $action.ToLower() )  {
            "get"    { $desc = "The code and the body of the response message. `r`nStatus: " + $code + " `r`nThe body contains the " + $thing.ToLower() + "(s) that match(es) the specified ID or the specified criteria in the query." }
            default  { $desc = $codenode.description }
        }
        if ( IsValid $desc )  { $newnode = AddKeyValue $newnode "sectionDescription" $desc }

        $defname = GetRefName $codenode.schema.'$ref'
        $dtonode = MkDtoNode $defname $thing $action
        if ( IsValid $dtonode.syntax )      { $newnode = AddKeyValue $newnode "syntax" $dtonode.syntax }  # NOTE: $dtonode.syntax is already prettified.
        # BUGBUG: Do not add the dto fields to mainParams, which takes webapiparams, but webapiparams in the webapidto definition would cause a circular reference.
        # $cleandtofields = $dtonode.fields | foreach { $_ -replace "^_id-", "" -replace "_\Z", "" }
        # if ( $dtonode.fields.Count -gt 0 )  { $newnode = AddKeyIDList $newnode "mainParams" $cleandtofields }

        $global:permssections += $newnode
        $global:listsections  += $newnode.name

        return $newnode
    }
    else  {
        $oldnode = GetPermNode $global:permssections $name
        return $oldnode
    }
}

# $apigroup.ToLower() $action $name $actionnode.summary
function MkMethodSummary( [string] $thing1, [string] $action, [string] $apiname, [string] $defaultsummary )  {
    $thing1 = $thing1.ToLower()
    $things = $thing1 + "s"
    $namearr = $apiname.ToLower().Replace( "{", "" ).Replace( "}", "" ).Split( "/", [System.StringSplitOptions]::RemoveEmptyEntries )

    switch ( $action.ToLower() )  {
        "get"  {
            if ( $namearr -contains "id" ) {
                return "Gets the specified $thing1."
            }
            elseif ( $namearr -contains "getbyids" ) {
                return "Gets the specified $things."
            }
            elseif ( $namearr -contains "name" )  {
                return "Gets the $thing1 whose name exactly matches the specified name."
            }
            else  {
                return "Gets all $things that match the criteria in the query."
            }
        }
        "post"  {
            return "Creates a new $thing1."
        }
        "put"  {
            return "Updates the specified $thing1."
        }
        "delete"  {
            return "Deletes the specified $thing1."
        }
    }

    return $defaultsummary
}

function MkFieldDesc( [string] $thing1, [string] $action, [string] $fldname, [string] $defaultdesc )  {
    $thing1 = $thing1.ToLower()

    switch ( $fldname )  {
        "id"  {
            switch ( $action )  {
                "get"     { return "The unique identifier of the $thing1 to get."    }
                "post"    { break }
                "put"     { return "The unique identifier of the $thing1 to update." }
                "delete"  { return "The unique identifier of the $thing1 to delete." }
                "dto"     { return "The unique identifier of the $thing1." }
            }
        }
        "language"  {
            switch ( $action )  {
                "get"     { return "The language of the $thing1 to get."  }
                "post"    { return "The language of the $thing1 to create." }
                "put"     { return "The language of the $thing1 to update." }
                "delete"  { break }
                "dto"     { return "The language of the $thing1." }
            }
        }
        "publish"  {
            switch ( $action )  {
                "get"     { break }
                "post"    { return "If <term>true</term>, the new $thing1 is immediately published. Default is <term>false</term>."  }
                "put"     { return "If <term>true</term>, the updated $thing1 is immediately published. Default is <term>false</term>."  }
                "delete"  { break }
                "dto"     { return "If <term>true</term>, the $thing1 is published."  }
            }
        }
        "tags"  {
            switch ( $action )  {
                "get"     { break }
                "post"    { return "The tags to assign to the new $thing1." }
                "put"     { return "The updated list of tags to assign to the $thing1." }
                "delete"  { break }
                "dto"     { return "The list of tags associated with the $thing1." }
            }
        }
        "contentTypeId"  {
            switch ( $action )  {
                "get"     { break }
                "post"    { return "The content type of the content item to create." }
                "put"     { return "The content type of the content item to update." }
                "delete"  { break }
                "dto"     { return "The content type of the content item." }
            }
        }
        "contentItem"  {
            switch ( $action )  {
                "get"     { break }
                "post"    { return "The settings for the new content item." }
                "put"     { return "The new settings for the specified content item." }
                "delete"  { break }
                "dto"     { return "The details of the content item." }
            }
        }

        # Query fields are only applicable to GET requests for both content types and content items.
        "query.published"      { return "If <term>true</term>, only published content items are included in the results. Default is <term>false</term>." }
        "query.tags"           { return "The tags to search for. Comma-separated and URL-encoded. Example: tags=my%20tag,tag2,lastTag" }
        "query.contentTypeId"  { return "The content type of the content items to return." }
        "query.searchText"     { return "The text to search for." }
        "query.startIndex"     { return "The index at which to start the returned results. Example: If the value is 5, the first five resulting items are ignored." }
        "query.maxItems"       { return "The maximum number of resulting items to return." }
        "query.fieldOrder"     { return "The field to be used for sorting the results. See <term>orderAsc</term>." }
        "query.orderAsc"       { return "If <term>true</true>, the results are sorted in ascending order of <term>fieldOrder</term>. Otherwise, in descending order." }
        "query.createdFrom"    { return "The earliest creation date to be included in the results. Use with <term>createdTo</term> to define a range of creation dates." }
        "query.createdTo"      { return "The latest creation date to be included in the results. Use with <term>createdFrom</term> to define a range of creation dates." }

    }

    return $defaultdesc
}


function GetRefName( [string] $dtoref )  {
    return $dtoref.Replace( "#/definitions/", "" )
}
# BUGBUG: Accesses $global:defsnode directly.
function GetRefNode( [string] $dtoref )  {
    $refname = GetRefName $dtoref
    return $global:defsnode.$refname
}

# BUGBUG: Accesses $global:permsparams directly.
function MkURL( [string] $apiname, [string] $queryparams )  {
    $query = ""
    if ( $queryparams.Count -gt 0 )  { $query = "?query" }
    return "$apiurl$apiname$query"
}

# Retrieves the syntax for a DTO in the Definitions section.
# BUGBUG: Accesses $global:defsnode directly.
function GetRefSyntax( [string] $refname )  {
    if ( $global:defsnode.$refname.properties -is [PSObject] )  {
        $refpropsnode = $global:defsnode.$refname.properties
        $refsyntaxnode = [PSCustomObject]@{}
        foreach ( $propname in $refpropsnode.psobject.properties.name )  {
            if ( $refpropsnode.$propname.'type' )  { $refsyntaxnode = AddKeyValue $refsyntaxnode $propname $refpropsnode.$propname.'type' }
            if ( $refpropsnode.$propname.'$ref' )  {
                $arr = ($refpropsnode.$propname.'$ref').Replace( "#", "" ).Split( "/", [System.StringSplitOptions]::RemoveEmptyEntries )
                $subref = GetRefSyntax $arr[1]
                $refsyntaxnode = AddKeyValue $refsyntaxnode $propname $subref
            }
        }
    }
    return $refsyntaxnode
}
# Retrieves the syntax starting at the list of parameters of an action node.
# Calls GetRefSyntax for syntaxes for a DTO reference in the definitions section.
function MkSyntax( [PSObject] $actionnode, [string] $in )  {
    $syntaxnode = [PSCustomObject]@{}
    foreach ( $param in $actionnode.parameters )  {
        if (( IsNotValid $in ) -or ( StrCompare $param.'in' $in ))  {
            if ( $param.'type' )  { $syntaxnode = AddKeyValue $syntaxnode $param.name $param.'type' }
            if ( $param.schema.'$ref' )  {
                $arr = ($param.schema.'$ref').Replace( "#", "" ).Split( "/", [System.StringSplitOptions]::RemoveEmptyEntries )
                $subsyntax = GetRefSyntax $arr[1]
                $syntaxnode = AddKeyValue $syntaxnode $param.name $subsyntax
            }
        }
    }
    return $syntaxnode
}

function FilterParamsIn( [PSObject[]] $srclist, [string[]] $paramnames, [string] $infilter )  {
    $out = @()
    foreach ( $node in $srclist )  {
        if ( $paramnames -contains $node.name )  {
            if ( StrCompare $node.'in' $infilter )  {
                $out += $node.name
            }
        }
    }
    return $out
}

function MkFileNode( [PSObject] $filenode, [string] $webapiname, $permsnode )  {
    $addname = "add-$webapiname"
    foreach ( $perm in $permsnode )  {
        if ( $filenode.$addname.permutations -is [array] )  {
            $filenode.$addname.permutations += $perm
        }
    }
    return $filenode
}


# MAIN -------------------------------------------------------

if ( $args.Count -gt 2 )  {
    $srcuri  = $args[0]
    $srcfn   = $args[1]
    $tmplfn  = $args[2]
    $tgtdir  = $args[3]

    # Output files
    $tgtfnflds     = "$tgtdir\jobs-webapifields.out"
    $tgtfndtos     = "$tgtdir\jobs-webapidtos.out"
    $tgtfnparams   = "$tgtdir\jobs-webapiparams.out"
    $tgtfnsections = "$tgtdir\jobs-webapisections.out"
    $tgtfnmethods  = "$tgtdir\jobs-webapimethods.out"


    # Request the json from the Swagger website.
    if ( IsValid $srcuri )  {
        $webpage = Invoke-WebRequest -URI $srcuri
        if ( $webpage.StatusCode -eq 200 )  {
            $webpage.Content | Out-File $srcfn -Encoding DEFAULT
        }
    }
    # Source nodes
    $myjson = Get-Content -Raw -Path $srcfn | ConvertFrom-Json
    $pathsnode = $myjson.paths
    $global:defsnode = $myjson.definitions

    # Generate a webapimethod for each action for each api in the list, as well as the internal content items it needs.
    foreach ( $apiname in $apitypes )  {
        if ( $pathsnode.$apiname )  {
            $apigroup = GetAPIGroup $apiname  # Content Type or Content Item?
            $apinode = $pathsnode.$apiname
            foreach ( $action in $apinode.psobject.properties.name )  {
                # local lists (local to the method)
                $methodfields    = @()
                $methoddtos      = @()
                $methodparams    = @()
                $methodresponses = @()

                $actionnode = $apinode.$action
                $newmethodnode = [PSCustomObject]@{}

                # method - name
                $name = FlattenName $apiname
                $name = MkName "method" "" $action $apiname
                $newmethodnode = AddKeyValue $newmethodnode "name" $name

                # method - summary
                $summary = MkMethodSummary $apigroup $action $apiname $actionnode.summary
                if ( IsValid $summary )  {
                    $newmethodnode = AddKeyValue $newmethodnode "summary" $summary
                }

                # method - action
                $newmethodnode = AddKeyValue $newmethodnode "action" $action.ToUpper()


                # Create webapifields or webapidtos for each of the parameters, if they don't already exist.
                foreach ( $param in $actionnode.parameters )  {
                    $newparamnode = [PSCustomObject]@{}

                    # webapiparam
                    $name = MkName "param" $apigroup $action $param.name
                    $methodparams += $name
                    if ( $global:listparams -notcontains $name )  {
                        if ( $name )            { $newparamnode = AddKeyValue $newparamnode "name" $name }
                        if ( $param.name )      { $newparamnode = AddKeyValue $newparamnode "paramName" $param.name }
                        if ( $param.'in' )      { $newparamnode = AddKeyValue $newparamnode "in" $param.'in' }
                        if ( $param.required )  {
                            $newparamnode = AddKeyValue $newparamnode "requiredOptional" "Required"
                        }
                        else  {
                            $newparamnode = AddKeyValue $newparamnode "requiredOptional" "Optional"
                        }

                        # If 'type' property exists, it's a regular field. Save as webapifield.
                        if ( $param.'type' )  {
                            $newfieldnode = MkFieldNode $param $apigroup $action
                            $methodfields += $newfieldnode.name

                            # param - field
                            $newparamnode = AddKeyIDList $newparamnode "field" @( $newfieldnode.name )
                        }

                        # If 'schema' property exists, it's a reference field. Save as webapidto.
                        elseif ( $param.schema )  {
                            $defname = GetRefName $param.schema.'$ref'
                            $newdtonode = MkDtoNode $defname $apigroup $action
                            $methoddtos += $newdtonode.name

                            # param - dTO
                            $newparamnode = AddKeyIDList $newparamnode "dTO" @( $newdtonode.name )
                        }
                        $global:permsparams += $newparamnode
                        $global:listparams  += $newparamnode.name
                    }
                }

                # Sort parameters based on $in.
                if ( $methodparams.Count -gt 0 )  {
                    $pathparams  = FilterParamsIn $global:permsparams $methodparams "path"
                    $queryparams = FilterParamsIn $global:permsparams $methodparams "query"
                    $bodyparams  = FilterParamsIn $global:permsparams $methodparams "body"
                }

                # method - uRLSection - This section will always exist.
                $newurlnode = MkSectionNodeUrl $actionnode $apiname $apigroup $action $pathparams $queryparams
                if ( $newurlnode )  { $newmethodnode = AddKeyIDList $newmethodnode "uRLSection" @( $newurlnode.name ) }

                # method - messageSection - The body is required only for POST and PUT.
                if ( $bodyparams.Count -gt 0 )  {
                    $newbodynode = MkSectionNodeBody $actionnode $apiname $apigroup $action $bodyparams
                    if ( $newbodynode )  { $newmethodnode = AddKeyIDList $newmethodnode "messageSection" @( $newbodynode.name ) }
                }

                # method - responseSection - This section will always exist.
                $listrespnodes = @()
                foreach ( $code in $actionnode.responses.psobject.properties.name )  {
                    $codenode = $actionnode.responses.$code
                    $newrespnode = MkSectionNodeResponse $code $codenode $apiname $apigroup $action
                    if ( $newrespnode )  { $listrespnodes += $newrespnode.name }
                }
                if ( $listrespnodes.Count -gt 0 )  { $newmethodnode = AddKeyIDList $newmethodnode "responseSection" $listrespnodes }


                # method - remarks (to be added manually to the permutation)

                # method - relatedLinks (add links to relevant conceptuals based on $action)

                $global:permsmethods += $newmethodnode
                $global:listmethods  += $newmethodnode.name
            }
        }
        else  {
            Write-Error "WARNING: Missing definition for $apiname in $srcfn"
            return
        }

    }

    # Create jobs-webapi* file nodes from the templates and add the permutations list. Then convert to JSON and prettify.
    $mytempljson = Get-Content -Raw -Path $tmplfn | ConvertFrom-Json
    MkFileNode $mytempljson.webapifields   "webapifields"   $global:permsfields   | ConvertTo-Json -Depth 100 | PrettifyJson | Out-File $tgtfnflds     -Encoding DEFAULT
    MkFileNode $mytempljson.webapidtos     "webapidtos"     $global:permsdtos     | ConvertTo-Json -Depth 100 | PrettifyJson | Out-File $tgtfndtos     -Encoding DEFAULT
    MkFileNode $mytempljson.webapiparams   "webapiparams"   $global:permsparams   | ConvertTo-Json -Depth 100 | PrettifyJson | Out-File $tgtfnparams   -Encoding DEFAULT
    MkFileNode $mytempljson.webapisections "webapisections" $global:permssections | ConvertTo-Json -Depth 100 | PrettifyJson | Out-File $tgtfnsections -Encoding DEFAULT
    MkFileNode $mytempljson.webapimethods  "webapimethods"  $global:permsmethods  | ConvertTo-Json -Depth 100 | PrettifyJson | Out-File $tgtfnmethods  -Encoding DEFAULT
}
else  {
    Usage
}

# ============================================================
