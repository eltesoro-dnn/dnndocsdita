# ======================================================================
# Creates the boilerplates for apis.
# USAGE: powershell -file mkapi.ps1 qa-sc.dnnapi.com/swagger/docs/v1 json\swagger.json bptext-api .\out
# ======================================================================


# GENERAL FUNCTIONS ------------------------------------------

function IsValid( [string] $s )  {
    if ( $s -eq $NULL )  {
        return $FALSE
    }
    elseif ( $s -eq "" )  {
        return $FALSE
    }
    return $TRUE
}

function IsNotValid( [string] $s )  { return ( !(IsValid $s) ) }

function Hyphenated( [string] $s )  { return ( $s.ToLower().Replace( " ", "-" ).Replace( "/api/", "api-" ).Replace( "/", "-" ) -replace "[,(){}]" ) }

function Convert2RefName( [string] $s )  {
    $s = $s.Replace( "#/", "" ).Replace( "[", "-" ).Replace( "]", "" ) -replace "[/.]", "-"
    if ( $s.Contains( "definitions" ) )  {  return ( $s )  }
    else                                 {  return ( "definitions-" + $s )  }
}

function BreakPascal( [string] $str )  {
    $s = ""
    if ( $str )  {
        $s = ( $arr[1] -creplace "([A-Z])", " `$1" ).Trim()
    }
    return ( $s )
}

function ChkThenMkDir( [string] $folder )  {
    if ( -not( Test-Path $folder ) )  {
        New-Item  $folder  -Type directory | Out-Null
    }
}


function ExtractRefType( [string] $str )  {
    $arr = $str.Split( "-", [System.StringSplitOptions]::None )
    return( $arr[0] )
}
function MkFullRef( [string] $reftype, [string] $fn, [string] $anchor, [string] $wraptag )  {
    $conrefstr = "$reftype=""$fn/$anchor"""

    $tag = ExtractRefType $anchor

    # Don't duplicate the wraptag.
    if (( $wraptag ) -and ( $wraptag.CompareTo( $tag ) -ne 0 ))  {
        $wraptagstart = "<$wraptag>"
        $wraptagend   = "</$wraptag>"
    }

    # For notes. If it's a conref/conreftype, don't include the type.
    $notetype = " type=""$tag"""
    if ( $conrefstr.StartsWith( "conref" ) -or $conrefstr.StartsWith( "conkeyref" ) )  { $notetype = "" }

    switch ( $tag )  {
        "note"          { return "$wraptagstart<note$notetype $conrefstr></note>$wraptagend"; break }
        "important"     { return "$wraptagstart<note$notetype $conrefstr></note>$wraptagend"; break }
        "remember"      { return "$wraptagstart<note$notetype $conrefstr></note>$wraptagend"; break }
        "tip"           { return "$wraptagstart<note$notetype $conrefstr></note>$wraptagend"; break }
        "warning"       { return "$wraptagstart<note$notetype $conrefstr></note>$wraptagend"; break }
        "trouble"       { return "$wraptagstart<note$notetype $conrefstr></note>$wraptagend"; break }
        "simpletable"   { return "$wraptagstart<$tag $conrefstr><sthead><stentry/></sthead><strow><stentry/></strow></$tag>$wraptagend"; break }
        "strow"         { return "$wraptagstart<$tag $conrefstr><stentry/></$tag>$wraptagend"; break }
        "stentry"       { return "$wraptagstart<$tag $conrefstr></$tag>$wraptagend"; break }
        "substeps"      { return "$wraptagstart<$tag $conrefstr><substep><cmd/></substep></$tag>$wraptagend"; break }
        "choices"       { return "$wraptagstart<$tag $conrefstr><choice/></$tag>$wraptagend"; break }
        "ul"            { return "$wraptagstart<$tag $conrefstr><li/></$tag>$wraptagend"; break }
        "ol"            { return "$wraptagstart<$tag $conrefstr><li/></$tag>$wraptagend"; break }
        "parml"         { return "$wraptagstart<$tag $conrefstr><plentry><pt/><pd/></plentry></$tag>$wraptagend"; break }
        "plentry"       { return "$wraptagstart<$tag $conrefstr><pt/><pd/></$tag>$wraptagend"; break }
        "ph"            { return "$wraptagstart<$tag $conrefstr></$tag>$wraptagend"; break }
        default         { return "$wraptagstart<$tag $conrefstr></$tag>$wraptagend" }
    }
}
# $str could be "conref=type-name" or "conkeyref=$conkeyreflocal/type-name" or "img=filepath|alt"
function MkConref( [string] $str, [string] $wraptag )  {
    $refarr = $str.Split( "=", [System.StringSplitOptions]::None )

    $retval = $str
    switch -exact ( $refarr[0] )  {
        "conref" {
            $retval = MkFullRef $refarr[0] $conreffilelocal $refarr[1] $wraptag
            break
        }
        "conkeyref" {
            $arr = ($refarr[1]).Split( "/", [System.StringSplitOptions]::None )
            $retval = MkFullRef $refarr[0] $arr[0] $arr[1] $wraptag
            break
        }
        "img" {
            $arr = ($refarr[1]).Split( "=|", [System.StringSplitOptions]::None )
            $img = $arr[0]
            $alt = $arr[1]
            $outputclass = "img"
            foreach ( $imgtype in ( "scr", "gra", "ico" ) ) {
                if ( $img.StartsWith( "$imgtype-" ) ) {
                    $outputclass = "img-$imgtype"
                }
            }

            if ( $wraptag )  {
                $wraptagstart = "<$wraptag>"
                $wraptagend   = "</$wraptag>"
            }
            $retval = "$wraptagstart<image outputclass=""$outputclass"" scalefit=""yes"" placement=""break"" align=""left"" href=""../../common/img/$img""><alt>$alt</alt></image>$wraptagend"
            break
        }
        default {
            if ( $wraptag )  {
                if ( $notetypes -contains $wraptag )  {
                    $retval = "<note type=$wraptag>$str</note>"
                }
                elseif ( $wraptag.CompareTo( $refarr[0] ) -eq 0 )  {
                    $retval = "$str"
                }
                else  {
                    $retval = "<$wraptag>$str</$wraptag>"
                }
            }
        }
    }
    return( $retval )
}
function WriteConref( [string] $value, [string] $prefix, [string] $indent )  {
    $refname = Convert2RefName $value
    $conref = "conkeyref=$conkeyreflocal/" + $prefix + "-" + $refname
    $newconref = MkConref $conref
    Write-Output "$indent$newconref"
}


function CountParams( [PSCustomObject] $paramnode, [string] $field, [string] $value )  {
    $count = 0
    if ( $field )  {
        $paramnode | Where-Object { $_.$field -eq $value } | foreach  { $count += 1 }
    }
    else  {
        $paramnode | foreach  { $count += 1 }
    }
    return ( $count )
}
function CountChildren( [PSCustomObject] $parentnode )  {
    $count = 0
    $parentnode.psobject.properties.name | foreach  {
        if ( IsValid $_ ) {
            $count += 1
        }
    }
    return ( $count )
}


function WriteSingleKeyValue( [string] $field, [PSCustomObject] $node, [string] $indent )  {
    if ( $field.CompareTo( '$ref' ) -eq 0 )  {
        if ( $node -and ( $node.StartsWith( "#/" ) ) )  {
            $repl = $node.Replace( "#/definitions/", "" )
            WrapAndWriteNodeAsSchema $definitionsnode.$repl "$indent"
        }
    }
    elseif ( $field.CompareTo( "enum" ) -eq 0 )  {
        Write-Output "$indent""enum"" :"
        Write-Output "$indent$tab["
        foreach ( $name in $node.psobject.properties.name )  {
             Write-Output "$indent$tab$name"
        }
        Write-Output "$indent$tab]"
    }
    else  {
        if ( $node.'$ref' )  {
            $sub = $node.'$ref'
            if ( $sub.CompareTo( "System.Object" ) -eq 0 )  {
                Write-Output "$indent""$field"" : System.Object"
            }
            elseif ( $sub.StartsWith( "#/" ) )  {
                Write-Output "$indent""$field"" :"
                WriteSingleKeyValue '$ref' $sub "$indent$tab"
            }
            else  {
                Write-Output "$indent""$field"" :  <!-- $sub -->"
                WrapAndWriteNodeAsSchema $definitionsnode.$sub "$indent$tab"
            }
        }

        else  {
            if     ( $node.'type' )  {  $value = $node.'type'  }
            elseif ( $node.$field )  {  $value = $node.$field  }
            else                     {  $value = $node         }

            if ( $value -is [string] )  {
                Write-Output "$indent""$field"" : ""$value"""
            }
            elseif ( $value -is [PSCustomObject] )  {
                Write-Output "$indent""$field"" :"
                WrapAndWriteNodeAsSchema $value  "$indent$tab"
            }
        }
    }
}
function IsTypeArray( [PSCustomObject] $node )  {
    $childnames = $node.psobject.properties.name
    if ( $childnames )  {
        if ( $childnames.Contains( "type" ) -and $childnames.Contains( "items" ) )  {
            return ( ($node.'type').CompareTo( "array" ) -eq 0 )
        }
    }
    return( $false )
}
function IsCustomObject( [PSCustomObject] $node )  {
    $childnames = $node.psobject.properties.name
    if ( $childnames )  {
        if ( $childnames.Contains( "type" ) -and $childnames.Contains( "properties" ) )  {
            if ( ($node.'type').CompareTo( "System.Object" ) -eq 0 )  {  # special case
                return ( $false )
            }
            else  {
                return ( ($node.'type').CompareTo( "object" ) -eq 0 )
            }
        }
    }
    return( $false )
}
function WriteNodeAsSchema( [PSCustomObject] $node, [string] $indent )  {
    if ( IsTypeArray $node )  {
        Write-Output "$indent["
        foreach ( $item in $node.'items'.psobject.properties.name )  {
            WriteSingleKeyValue $item $node.'items'.$item "$indent$tab"
        }
        Write-Output "$indent$tab, ..."
        Write-Output "$indent]"
    }
    elseif ( IsCustomObject $node )  {
        foreach ( $prop in $node.'properties'.psobject.properties.name )  {
            WriteSingleKeyValue $prop $node.'properties'.$prop "$indent"
        }
    }
    else  {
        foreach ( $name in $node.psobject.properties.name )  {
            WriteSingleKeyValue $name $node.$name $indent
        }
    }
}
function WrapAndWriteNodeAsSchema( [PSCustomObject] $node, [string] $indent )  {
    $count = CountChildren $node
    $isList = $true
    if ( $count -eq 1 )  {
        $node.psobject.properties.name | foreach {
            if ( $_.CompareTo( '$ref' ) -eq 0 )  {
                $isList = $false
            }
        }
    }
    $innertab = $indent
    if ( $isList )  {
        Write-Output "$indent{"
        $innertab = "$indent$tab"
    }
    WriteNodeAsSchema $node $innertab
    if ( $isList )  {
        Write-Output "$indent}"
    }
}


function WriteSingleParam( [string] $field, [PSCustomObject] $node, [string] $indent )  {
    if ( $field.CompareTo( '$ref' ) -eq 0 )  {
        WriteConref $node "parml" $indent
    }
    else  {
        $opt = ""
        if ( $node.required -eq $false ) {
            $opt = "(Optional) "
        }

        $type = ""
        if ( $node.'type' )  {
            $type = "[" + $node.'type' + "] "
        }

        $desc = $node.description

        Write-Output "$indent<plentry>"
        Write-Output "$indent$tab<pt>$field</pt>"
        if ( $node.'$ref' )  {
            Write-Output "$indent$tab<pd>"
            if ( $opt -or $desc )  {  Write-Output "$indent$tab$tab$opt$desc"  }
            WriteSingleParam '$ref' $node.'$ref' "$indent$tab$tab"
            Write-Output "$indent$tab</pd>"
        }
        else  {
            Write-Output "$indent$tab<pd>$type$opt$desc</pd>"
        }
        Write-Output "$indent</plentry>"
    }
}
function WriteURLParams( [PSCustomObject] $paramnode, [string] $invalue, [string] $indent )  {
    $paramnode | Where-Object { $_.in -eq $invalue } | foreach  {
        WriteSingleParam $_.name $_ "$indent"
    }
}
function WriteNodeAsParams( [PSCustomObject] $node, [string] $indent )  {
    $node.psobject.properties.name | foreach {
        WriteSingleParam $_ $node.$_ $indent
    }
}
function WrapAndWriteNodeAsParams( [PSCustomObject] $node, [string] $indent )  {
    $count = CountChildren $node
    $isList = $true
    if ( $count -eq 1 )  {
        $node.psobject.properties.name | foreach {
            if ( $_.CompareTo( '$ref' ) -eq 0 )  {
                $isList = $false
            }
        }
    }
    $innertab = $indent
    if ( $isList )  {
        Write-Output "$indent<parml outputclass=""docindent"">"
        $innertab = "$indent$tab"
    }
    WriteNodeAsParams $node $innertab
    if ( $isList )  {
        Write-Output "$indent</parml>"
    }
}


# FUNCTIONS FOR BPTEXT ---------------------------------------

function WriteStartBP( [string] $thisscript, [string] $params, [string] $indent )  {
    Write-Output ""
    Write-Output "$indent<!-- =================================================== -->"
    Write-Output "$indent<!-- This section was generated by running: powershell -file $thisscript $params -->"
    Write-Output "$indent<!-- START GENERATED SECTION -->"
}
function WriteEndBP( [string] $indent )  {
    Write-Output ""
    Write-Output "$indent<!-- END GENERATED SECTION -->"
    Write-Output "$indent<!-- =================================================== -->"
}


function WriteBPs( [PSCustomObject] $node, [string] $indent )  {
    Write-Output ""
    Write-Output ""
    Write-Output "$indent<section id=""definitions"">"
    foreach ( $defname in $node.psobject.properties.name )  {
        $refname  = Convert2RefName $defname
        $defdesc  = $node.$defname.description
        $defprops = $node.$defname.properties

        if ( -not $refname.Contains( "System-Object" ) )  {
            Write-Output ""
            Write-Output ""

            # Syntax in JSON
            $phrefname = "ph-" + $refname
            $conref = "conkeyref=""$conkeyreflocal/" + $phrefname + """"
            Write-Output "$indent$tab<!-- <ph $conref></ph> -->"
            Write-Output "$indent$tab<ph id=""$phrefname"">"
            Write-Output "{"
            foreach ( $prop in $defprops )  {
                WriteNodeAsSchema $prop "$tab"
            }
            Write-Output "}"
            Write-Output "$indent$tab</ph>"

            # Parameter list
            $parmlrefname = "parml-" + $refname
            $conref = "conkeyref=""$conkeyreflocal/" + $parmlrefname + """"
            Write-Output "$indent$tab<!-- <parml $conref><plentry><pt/><pd/></plentry></parml> -->"
            Write-Output "$indent$tab<parml id=""$parmlrefname"" outputclass=""docindent"">"
            foreach ( $prop in $defprops )  {
                WriteNodeAsParams $prop "$indent$tab$tab"
            }
            Write-Output "$indent$tab</parml>"
        }
    }
    Write-Output ""
    Write-Output ""
    Write-Output "$indent</section>"
}


# FUNCTIONS FOR TOPICS ---------------------------------------

function WriteTopicStart( [string] $topictype, [string] $navdashed )  {
    Write-Output "<?xml version=""1.0"" encoding=""utf-8"" standalone=""no""?>"
    switch ( $topictype )  {
        "task"  {
            Write-Output "<!DOCTYPE $topictype PUBLIC ""-//OASIS//DTD DITA General Task//EN"" ""http://docs.oasis-open.org/dita/v1.2/os/dtd1.2/technicalContent/dtd/generaltask.dtd"">"
            Write-Output "<$topictype xml:lang=""en"" id=""tsk-$navdashed"">"
            break
        }
        "topic"  {
            Write-Output "<!DOCTYPE $topictype PUBLIC ""-//OASIS//DTD DITA Topic//EN"" ""http://docs.oasis-open.org/dita/v1.2/os/dtd1.2/technicalContent/dtd/topic.dtd"">"
            Write-Output "<$topictype xml:lang=""en"" id=""top-$navdashed"">"
            break
        }
        "reference"  {
            Write-Output "<!DOCTYPE $topictype PUBLIC ""-//OASIS//DTD DITA Reference//EN"" ""http://docs.oasis-open.org/dita/v1.2/os/dtd1.2/technicalContent/dtd/reference.dtd"">"
            Write-Output "<$topictype xml:lang=""en"" id=""ref-navdashed"">"
            break
        }
    }
    Write-Output ""
}
function WriteTopicEnd( [string] $topictype )  {
    Write-Output ""
    Write-Output "</$topictype>"
}


function BodyTag( [string] $topictype )  {
    switch ( $topictype )  {
        "task"       { return "taskbody"; break }
        "topic"      { return "body"; break }
        "reference"  { return "refbody"; break }
    }
}


function MkTopicTitle( [string] $apiname )  {
    $arr = $apiname.Split( "/", [System.StringSplitOptions]::RemoveEmptyEntries )
    $title = BreakPascal $arr[1]
    foreach ( $comp in $arr )  {
        switch( $comp )  {
            "usages"            { $title += " Usage Counts" }
            "referenceobjects"  { $title += " Referenced Objects" }
            "ClientReferenceId" { $title += " with Client Reference ID" }
            "{id}"              { $title += " with ID" }
            "GetByIds"          { $title += " with ID Array" }
        }
    }
    return ( $title )
}
function WriteTitles( [string] $apiname, [string] $method, [string] $indent )  {
    $methodup = $method.ToUpper()
    $title = MkTopicTitle $apiname


    Write-Output ""
    Write-Output "$indent<title>$methodup $title</title>"
    Write-Output "$indent<titlealts>"
    Write-Output "$indent$tab<navtitle>$methodup $title</navtitle>"
    Write-Output "$indent</titlealts>"
}


function WriteAPIDesc( [string] $apiname, [string] $method, [PSCustomObject] $node, [string] $indent )  {
    $desc = $node.summary
    $methodup = $method.ToUpper()

    Write-Output ""
    Write-Output "$indent<section id=""apidesc"">"
    Write-Output "$indent$tab<title>$methodup $apiname</title>"
    Write-Output "$indent$tab<p>$desc</p>"
    Write-Output "$indent</section>"
}


function WriteResponse( [string] $apiname, [PSCustomObject] $node, [string] $indent )  {
    # Section title
    Write-Output ""
    Write-Output ""
    Write-Output "$indent<section id=""http-response-body"">"
    Write-Output "$indent$tab<title>HTTP Response</title>"

    # NOTE: Assumes that there is only one parameter where "in" == "body".
    $node.responses | foreach  {
        $status = $_.psobject.properties.name
        Write-Output ""
        Write-Output "$indent$tab$tab<p outputclass=""docindent"">Status: <systemoutput>$status</systemoutput></p>"

        # Codeblock for schema
        Write-Output ""
        Write-Output "<codeblock outputclass=""syntaxblock docindent"">"
        WrapAndWriteNodeAsSchema $_.$status.schema ""
        Write-Output "</codeblock>"

        # Parameters for schema
        Write-Output ""
        Write-Output "$indent$tab<!-- Response Schema Values -->"
        WrapAndWriteNodeAsParams $_.$status.schema "$indent$tab"
    }

    Write-Output "$indent</section>"
}


function WriteDTOParams( [string] $apiname, [PSCustomObject] $node, [string] $indent )  {
    Write-Output ""
    Write-Output "$indent<sectiondiv id=""sectiondiv-messagebody"">"
    Write-Output ""
    Write-Output "$indent$tab<p outputclass=""sectiondivtitle docindent"">In the message body,</p>"
    Write-Output ""

    # NOTE: Assumes that there is only one parameter where "in" == "body".
    $node.parameters | Where-Object { $_.in -eq "body" } | foreach  {
        # Description of the "body" parameter.
        $desc = $_.description
        Write-Output "$indent$tab<p outputclass=""docindent"">$desc</p>"

        # Codeblock for schema
        Write-Output ""
        Write-Output "<codeblock outputclass=""syntaxblock docindent"">"
        WriteNodeAsSchema $_.schema ""
        Write-Output "</codeblock>"

        # Parameters for schema
        Write-Output ""
        Write-Output "$indent$tab<!-- Message Body Schema Values -->"
        WrapAndWriteNodeAsParams $_.schema "$indent$tab"
    }

    Write-Output "$indent</sectiondiv>"
}
function WriteURLSyntax( [string] $apiname, [PSCustomObject] $node, [string] $indent )  {
    Write-Output ""
    Write-Output "$indent<sectiondiv id=""sectiondiv-url"">"

    # Codeblock for syntax
    $countparams = CountParams $node.parameters "in" "query"
    $querytext = ""
    if ( $countparams -gt 0 )  {
        $querytext = "?<varname>query</varname>"
    }
    $newapiname = $apiname.Replace( "{", "<varname>{" ).Replace( "}", "}</varname>" )
    $syntaxcode = "<ph conkeyref=""$conkeyreflocal/ph-apibaseurl""></ph>$newapiname$querytext"
    Write-Output ""
    Write-Output "$indent$tab<p outputclass=""sectiondivtitle docindent"">In the URL,</p>"
    Write-Output ""
    Write-Output "<codeblock outputclass=""syntaxblock docindent"">"
    Write-Output "$syntaxcode"
    Write-Output "</codeblock>"

    # Parameters
    $countpath  = CountParams $node.parameters "in" "path"
    $countquery = CountParams $node.parameters "in" "query"
    $countall = $countpath + $countquery
    if ( $countall -gt 0 )  {
        Write-Output ""
        Write-Output "$indent$tab<parml outputclass=""docindent"">"

        if ( $countpath -gt 0 )  {
            Write-Output "$indent$tab<!-- Path Parameters -->"
            WriteURLParams $node.parameters "path"  "$indent$tab$tab"
        }
        if ( $countquery -gt 0 )  {
            Write-Output "$indent$tab<!-- Query Fields -->"
            Write-Output "$indent$tab$tab<plentry>"
            Write-Output "$indent$tab$tab$tab<pt>query</pt>"
            Write-Output "$indent$tab$tab$tab<pd>Can include the following keys and their associated values:"
                Write-Output "$indent$tab$tab$tab$tab<parml outputclass=""docindent"">"
                WriteURLParams $node.parameters "query" "$indent$tab$tab$tab$tab$tab"
                Write-Output "$indent$tab$tab$tab$tab</parml>"
            Write-Output "$indent$tab$tab$tab</pd>"
            Write-Output "$indent$tab$tab</plentry>"
        }
        Write-Output "$indent$tab</parml>"
    }

    Write-Output "$indent</sectiondiv>"
}
function WriteRequest( [string] $apiname, [PSCustomObject] $node, [string] $indent )  {
    # Section title
    $title = "HTTP Request"
    $sectionid = Hyphenated $title
    Write-Output ""
    Write-Output ""
    Write-Output "$indent<section id=""$sectionid"">"
    Write-Output "$indent$tab<title>$title</title>"

    WriteURLSyntax $apiname $node "$indent$tab"
    if (( $method.ToUpper() -eq "PUT"  ) -or ( $method.ToUpper() -eq "POST" )) {
        WriteDTOParams $apiname $node "$indent$tab"
    }

    Write-Output "$indent</section>"
}


function WriteTopic( [string] $topictype, [string] $apiname, [string] $method, [string] $hyph, [PSCustomObject] $node )  {

    if ( $node.deprecated -eq $true )  {
        Write-Output "*** DEPRECATED ***"
    }

    else  {
        WriteTopicStart $topictype $hyph-$method
        $bodytag = BodyTag $topictype

        WriteTitles $apiname $method "$tab"
        # WriteProlog $node "$tab"

        Write-Output ""
        Write-Output "$tab<$bodytag>"

        WriteAPIDesc $apiname $method $node "$tab$tab"
        WriteRequest $apiname $node "$tab$tab"
        WriteResponse $apiname $node "$tab$tab"

        # WriteSection  $node.remarks  "remarks"  "$tab$tab"
        # WriteRelLinks $node.rellinks "$tab$tab"

        Write-Output ""
        Write-Output "$tab</$bodytag>"
        WriteTopicEnd $topictype
    }
}


# GLOBAL VARIABLES -------------------------------------------

# "author" : "wrET,1705"
# ,"audience" : [
#     {   "audtype" : "programmer"
#         ,"audjob" : "programming"
#     }
# ]
# ,"products" : [ "P91", "C91","E91" ]

$methods = @( "get", "post", "put", "delete" )


# MAIN -------------------------------------------------------

if ( $args.Count -gt 2 )  {
    $srcuri = $args[0]
    $srcfn = $args[1]
    $bpfnbase = $args[2]
    $tgtdir = $args[3]

    $conreffilelocal = "$bpfnbase.dita#top-$bpfnbase"
    $conkeyreflocal  = "k-bpapi"

    $thisscript = $MyInvocation.MyCommand.Name
    $params = [string]::Join( " ", $args )

    # $myjson = Get-Content -Raw -Path $srcfn | ConvertFrom-Json
    if ( IsValid $srcuri )  {
        $webpage = Invoke-WebRequest -URI $srcuri
        if ( $webpage.StatusCode -eq 200 )  {
            $webpage.Content | Out-File $srcfn -Encoding DEFAULT
        }
    }

    $myjson = Get-Content -Raw -Path $srcfn | ConvertFrom-Json
    $definitionsnode = $myjson.definitions

    $tab = "    "
    $indent = "$tab$tab"


    # BPTEXT -------------------------------------------------------

    $tgtfile = "$tgtdir\$bpfnbase.dita"
    Write-Output "" | Out-File $tgtfile -Encoding DEFAULT

    WriteStartBP $thisscript $params $indent | Out-File $tgtfile -Append -Encoding DEFAULT
    WriteBPs $definitionsnode $indent        | Out-File $tgtfile -Append -Encoding DEFAULT
    WriteEndBP $indent                       | Out-File $tgtfile -Append -Encoding DEFAULT


    # TOPICS -------------------------------------------------------

    $apinames = $myjson.paths.psobject.properties.name

    foreach ( $apiname in $apinames )  {
        $hyph = Hyphenated $apiname

        foreach ( $method in $methods )  {
            if ( $myjson.paths.$apiname.$method )  {
                $methodnode = $myjson.paths.$apiname.$method
                $tgtfile = "$tgtdir\$hyph-$method.dita"

                Write-Host "Creating $tgtfile...."
                WriteTopic "topic" $apiname $method $hyph $methodnode | Out-File $tgtfile -Encoding DEFAULT
            }
        }
    }
}

# ============================================================
