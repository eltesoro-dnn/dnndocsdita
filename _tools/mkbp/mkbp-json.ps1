# ======================================================================
# Creates the boilerplates for steps.
# USAGE: powershell -file mkbp-json-v2.ps1 json\foo.json bptext-foo .\out
#
# WARNINGS:
#   * For overlays on the image:
#       - Do NOT use "align=". It creates a <div> around the image.
#       - Do NOT use "placement="break"". It adds <br/> before and after the image.
# ======================================================================


# FUNCTIONS FOR BPTEXT ---------------------------------------

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

function Hyphenated( [string] $s )  { return ( $s.Replace( " ", "-" ).Replace( ",", "" ).Replace( "(", "" ).Replace( ")", "" ).ToLower() ) }

function ExtractRefType( [string] $str )  {
    $arr = $str.Split( "-", [System.StringSplitOptions]::None )
    return( $arr[0] )
}


function WriteStringOrArray( [PSCustomObject] $node, [string] $nodetag, [string] $childtag, [string] $indent )  {
    # if $node is an array:
    #   * $nodetag is the tag around the ENTIRE array.
    #   * $childtag is the tag around EACH item in the array.
    # if $node is a string:
    #   * <$nodetag><$childtag>$node</$childtag></$nodetag>

    if ( $node -is [System.Array] )  {
        # Array has multiple items.
        if ( $node.Count -gt 1 )  {
            if ( $nodetag )  { Write-Output ( "$indent<$nodetag>" ) }
            $node | foreach  {
                if ( $_ -is [String] )  {
                    $s = MkConref $_ $childtag
                    Write-Output ( "$indent$tab$s" )
                }
                else  {
                    WriteStringOrArray $_ $childtag "" $indent
                }
            }
            if ( $nodetag )  { Write-Output ( "$indent</$nodetag>" ) }
        }
        # Array has only one item.
        else  {
            $s = MkConref $node[0] $childtag
            if ( $nodetag )  { Write-Output ( "$indent<$nodetag>$s</$nodetag>" ) }
            else             { Write-Output ( "$indent$s" ) }
        }
    }
    if ( $node -is [String] )  {
        if ( $node.StartsWith( "conref" ) -or $node.StartsWith( "conkeyref" ) )  {
            $s = MkConref $node $nodetag
            Write-Output ( "$indent$s" )
        }
        else  {
            $s = MkConref $node $childtag
            if ( $nodetag )  { Write-Output ( "$indent<$nodetag>$s</$nodetag>" ) }
            else             { Write-Output ( "$indent$s" ) }
        }
    }
}
function WriteList( [PSCustomObject] $node, [string] $wraptag, [string] $indent )  {
    # $wraptag can be "ol" or "ul".
    WriteStringOrArray $node $wraptag "li" $indent
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
        "ph"            { return "$wraptagstart<$tag $conrefstr></$tag>$wraptagend"; break }
        default         { return "$wraptagstart<$tag $conrefstr></$tag>$wraptagend" }
    }
}
# $str could be "conref=type-name" or "conkeyref=k-pbbar/type-name" or "img=filepath|alt"
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


function WriteBP( [PSCustomObject] $node, [string] $indent )  {
    $id = $node.id
    $tag = ExtractRefType $id
    $text = $node.text

    $parenttag = ""
    if ( $tag.CompareTo( "ph" ) -eq 0 )  {
        $parenttag = "p"
    }

    if ( $tag.CompareTo( "lines" ) -eq 0 )  {
        $indent = ""
    }

    Write-Output ""
    if ( $notetypes -contains $tag ) {
        Write-Output "$indent<!-- <note conref=""$conreffilelocal/$id""></note> -->"
        Write-Output "$indent<note type=""$tag"" id=""$id"">$text</note>"
    }
    else  {
        Write-Output "$indent<!-- <$tag conref=""$conreffilelocal/$id""></$tag> -->"
        if ( $parenttag )   { Write-Output "$indent<$parenttag><$tag id=""$id"">$text</$tag></$parenttag>" }
        else                { Write-Output "$indent<$tag id=""$id"">$text</$tag>" }
    }
}


function WriteBPList( [PSCustomObject] $node, [string] $indent )  {
    $id = $node.id
    $tag = ExtractRefType $id
    $items = $node.items

    Write-Output ""
    Write-Output "$indent<!-- <$tag conref=""$conreffilelocal/$id""><li/></$tag> -->"
    Write-Output "$indent<$tag id=""$id"">"
    $items | foreach  { Write-Output "$indent$tab<li>$_</li>" }
    Write-Output "$indent</$tag>"
}


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


function WriteNotes( [PSCustomObject] $nodes, [string] $indent )  {
    if ( $nodes -is [system.array] )  {
        Write-Output ""
        Write-Output "$indent<section>"

        foreach ( $node in $nodes ) {
            if ( $node -is [system.array] )  {
            }
            $prefix = ExtractRefType $node.id
            switch ( $prefix ) {
                "note"          { WriteBP     $node "$indent$tab"; break }
                "important"     { WriteBP     $node "$indent$tab"; break }
                "remember"      { WriteBP     $node "$indent$tab"; break }
                "tip"           { WriteBP     $node "$indent$tab"; break }
                "warning"       { WriteBP     $node "$indent$tab"; break }
                "trouble"       { WriteBP     $node "$indent$tab"; break }
                "p"             { WriteBP     $node "$indent$tab"; break }
                "ph"            { WriteBP     $node "$indent$tab"; break }
                "lines"         { WriteBP     $node "$indent$tab"; break }
                "ul"            { WriteBPList $node "$indent$tab"; break }
                "ol"            { WriteBPList $node "$indent$tab"; break }
            }
        }

        Write-Output ""
        Write-Output "$indent</section>"
    }
}


function WriteSTHead( [PSCustomObject] $titles, [string] $indent )  {
    if ( IsNotValid $titles )  {
        $titles = @( "Field", "Description" )
    }
    Write-Output "$indent<sthead>"
    foreach( $title in $titles )  {
        Write-Output "$indent$tab<stentry>$title</stentry>"
    }
    Write-Output "$indent</sthead>"
}
function WriteSTRow( [PSCustomObject] $row, [string] $indent )  {
    if ( $row.id )  {
        $id = $row.id
    }
    elseif ( $row.fld )  {
        $hyph = Hyphenated ($row.fld).Replace( "conref=", "" ).Replace( "conkeyref=", "" )
        $id = "strow-field-$hyph"
    }
    else  {
        $id = ""
    }

    if ( $row -is [String] )  {
        $s = MkConRef $row
        Write-Output "$indent$s"
    }
    else  {
        if ( $id )  {
            Write-Output "$indent<!-- <strow conref=""$conreffilelocal/$id""><stentry/></strow> -->"
            Write-Output "$indent<strow id=""$id"">"
        }
        else  {
            Write-Output "$indent<strow>"
        }

        if ( $row.fld -and $row.desc ) {
            if ( ($row.fld).StartsWith( "conref" ) -or ($row.fld).StartsWith( "conkeyref" ) ) {
                WriteStringOrArray $row.fld  "stentry" ""          "$indent$tab"
            }
            else  {
                WriteStringOrArray $row.fld  "stentry" "uicontrol" "$indent$tab"
            }
            WriteStringOrArray $row.desc "stentry" "" "$indent$tab"
        }
        else  {
            WriteStringOrArray $row "" "stentry" "$indent"
        }

        Write-Output "$indent</strow>"
    }
}
function WriteSimpletables( [PSCustomObject] $nodes, [string] $indent )  {
    if ( $nodes.Count -gt 0 )  {
        Write-Output ( "" )
        Write-Output ( "$indent<section>" )

        foreach( $node in $nodes )  {
            $id = $node.id

            # column widths
            if ( $node.header.widths )  {
                $widths = ([string[]]$node.header.widths) -join " "
            }
            else  {
                $widths = "1* 3*"
            }

            # table start
            Write-Output ""
            Write-Output "$indent$tab<!-- <simpletable conref=""$conreffilelocal/$id""><sthead><stentry/></sthead><strow><stentry/></strow></simpletable> -->"
            Write-Output "$indent$tab<simpletable id=""$id"" relcolwidth=""$widths"">"

            # header
            WriteSTHead $node.header.titles "$indent$tab$tab"

            # rows
            foreach( $row in $node.rows )  {
                WriteSTRow $row "$indent$tab$tab"
            }

            # table end
            Write-Output "$indent$tab</simpletable>"
        }

        Write-Output ""
        Write-Output ( "$indent</section>" )
    }
}


# WriteSteps and Write1Step can be used for steps and substeps. Recursive with each other.
function Write1Step4bp( [PSCustomObject] $node, [string] $tag, [string] $indent )  {
    if ( $tag -notmatch "^sub" )  { Write-Output "" }
    if ( $node.id )  {
        $id = $node.id
        Write-Output "$indent<!-- <$tag conref=""$conreffilelocal/$id""><cmd/></$tag> -->"
        Write-Output "$indent<$tag id=""$id"">"
    }
    else  {
        Write-Output "$indent<$tag>"
    }

    $cmd = MkConRef $node.cmd "cmd"
    Write-Output "$indent$tab$cmd"

    if ( $node.info )  {
        WriteStringOrArray $node.info "info" "" "$indent$tab"
    }

    if ( $node.substeps )  {
        WriteSteps4bp $node.substeps "substeps" "$indent$tab"
    }

    if ( $node.choices )  {
        WriteSteps4bp $node.choices "choices" "$indent$tab"
    }

    if ( $node.xmp )  {
        if ( $node.xmp -is [String] )  {
            $s = "Example: " + $node.xmp
        }
        $s = MkConref $s "stepxmp"
        Write-Output "$indent$tab$s"
    }

    if ( $node.result )  {
        if ( $node.result -is [String] )  {
            $s = "Result: " + $node.result
        }
        $s = MkConref $s "stepresult"
        Write-Output "$indent$tab$s"
    }

    Write-Output "$indent</$tag>"
}
function WriteSteps4bp( [PSCustomObject] $nodes, [string] $parenttag, [string] $indent )  {
    if ( $nodes.Count -gt 0 )  {
        if ( $parenttag -notmatch "^sub" )  { Write-Output "" }
        if ( $nodes -is [String] )  {
            $s = MkConref $nodes
            Write-Output "$indent$s"
        }
        else  {
            Write-Output "$indent<$parenttag>"
            $tag = $parenttag.trimend( "s" )    # singular
            foreach ( $node in $nodes )  {
                if ( $node -is [String] )  {
                    $s = MkConref $node
                    Write-Output "$indent$s"
                }
                else  {
                    Write1Step4bp $node $tag "$indent$tab"
                }
            }
            if ( $parenttag -notmatch "^sub" )  { Write-Output "" }
            Write-Output "$indent</$parenttag>"
        }
        if ( $parenttag -notmatch "^sub" )  { Write-Output "" }
    }
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
        "task"  {
            return "taskbody"
            break
        }
        "topic"  {
            return "body"
            break
        }
        "reference"  {
            return "refbody"
            break
        }
    }
}


function WriteTitles( [PSCustomObject] $node, [string] $indent )  {
    $nav   = $node.nav
    $title = $node.title
    Write-Output ""
    Write-Output "$indent<title>$title</title>"
    Write-Output "$indent<titlealts>"
    Write-Output "$indent$tab<navtitle>$nav</navtitle>"
    Write-Output "$indent</titlealts>"
}


function WriteAuthor( [PSCustomObject] $node, [string] $indent )  {
    $author = $g_author
    if ( $node.author )    { $author = $node.author }
    Write-Output "$indent<author>$author</author>"
}


function WriteCopyright( [string] $yyyy, [string] $indent )  {
    Write-Output "$indent<copyright>"
    Write-Output "$indent$tab<copyryear year=""$yyyy""></copyryear>"
    Write-Output "$indent$tab<copyrholder>DNN Corp</copyrholder>"
    Write-Output "$indent</copyright>"
}


function MkAudience( [PSCustomObject] $aud )  {
    $validtypes = @( "user", "purchaser", "administrator", "programmer", "executive", "services" )
    $validjobs  = @( "installing", "customizing", "administering", "programming", "using", "maintaining", "troubleshooting", "evaluating", "planning", "migrating" )

    $type = $aud.audtype
    if ( $type )  {
        if ( $validtypes -contains $type )  { $type = "type=""$type""" }
        else                                { $type = "type=""other"" othertype=""$type""" }
    }

    $job = $aud.audjob
    if ( $job )  {
        if ( $validjobs -contains $job )    { $job = "job=""$job""" }
        else                                { $job = "job=""other"" otherjob=""$job""" }
    }

    return ( "<audience $type $job/>" )
}
function WriteAudience( [PSCustomObject] $node, [string] $indent )  {
    $audience = $g_audience
    if ( $node.audience )  { $audience = $node.audience }
    $audience | foreach  {
        $s = MkAudience $_
        Write-Output "$indent$s"
    }
}


function Write1ProdInfo( [string] $code, [string[]] $vrms, [string] $indent )  {
    if ( $vrms.Count -gt 0 )  {
        $name = ""
        switch ( $code )  {
            "P" { $name = "Platform"; break }
            "C" { $name = "Content"; break }
            "E" { $name = "Engage"; break }
        }
        Write-Output "$indent<prodinfo>"
        Write-Output "$indent$tab<prodname>$name</prodname>"
        WriteStringOrArray $vrms "vrmlist" "" "$indent$tab"
        Write-Output "$indent</prodinfo>"
    }
}
function WriteProdInfos( [PSCustomObject] $node, [string] $indent )  {
    $products = $g_products
    if ( $node.products )  { $products = $node.products }

    $prodP = @()
    $prodC = @()
    $prodE = @()
    $products | foreach  {
        $p = ($_.Substring( 0, 1 )).ToUpper()
        $v = $_.Substring( 1, 1 )
        $r = $_.Substring( 2, 1 )
        switch ( $p )  {
            "P" { $prodP += "<vrm version=""$v"" release=""$r""/>"; break }
            "C" { $prodC += "<vrm version=""$v"" release=""$r""/>"; break }
            "E" { $prodE += "<vrm version=""$v"" release=""$r""/>"; break }
        }
    }

    Write1ProdInfo "P" $prodP "$indent"
    Write1ProdInfo "C" $prodC "$indent"
    Write1ProdInfo "E" $prodE "$indent"
}


function WriteProlog( [PSCustomObject] $node, [string] $indent )  {
    $yyyy = Get-Date -Format yyyy
    $yymm = Get-Date -Format yymm

    Write-Output ""
    Write-Output "$indent<prolog>"

    WriteAuthor $node "$indent$tab"
    WriteCopyright $yyyy "$indent$tab"

    Write-Output "$indent$tab<metadata>"
    WriteAudience  $node "$indent$tab$tab"
    WriteProdInfos $node "$indent$tab$tab"
    Write-Output "$indent$tab</metadata>"

    Write-Output "$indent</prolog>"
}


function WriteAvail( [PSCustomObject] $node, [string] $indent )  {
    $avail = $g_avail
    if ( $node.avail )  { $avail = $node.avail }
    Write-Output ""
    Write-Output "$indent<section conkeyref=""k-bptext/section-prodavail-$avail""></section>"
}


function WritePrereq( [PSCustomObject] $node, [string] $indent )  {
    if ( $node.Count -gt 0 )  {
        Write-Output ""
        Write-Output "$indent<prereq>"
        WriteList $node "ul" "$indent$tab"
        Write-Output "$indent</prereq>"
    }
}


function AddAudience( [string] $s )  {
    # Add "audience=" to the step conref/conkeyref.
    if ( $s.Contains( "-host-" ) )  {
        $s = $s.Replace( "<step ", "<step audience=""adm"" " ).Replace( "<li ", "<li audience=""adm"" " )
    }
    ( "adm", "cmg", "mod" ) | foreach  {
        if ( $s.Contains( "-$_-" ) )  {
            $s = $s.Replace( "<step ", "<step audience=""$_"" " ).Replace( "<li ", "<li audience=""$_"" " )
        }
    }
    return $s
}
function FindLines( [string] $fn, [string] $stepli, [string] $pathhyphen )  {
    # Searches the file containing the conkeyrefs for pbar menus or tabs.
    $s = @()
    if ( Test-Path $fn )  {
        # Filter based on the hyphenated menu options (pathhyphen).
        Get-Content $fn | Where { $_.ToLower().Contains( $stepli.ToLower() ) -and $_.ToLower().Contains( $pathhyphen.ToLower() ) } | foreach  {
            $s += AddAudience $_
        }

        # BUGBUG: If there's both an adm line and a host line for pbar, choose host.
        $i = ( $s -like "*audience=""adm""*" ).Length
        if ( $i -gt 1 )  {
            $s = $s -notlike "*-adm-*"
        }
    }
    return $s
}
function WritePBarTags( [string] $step, [string] $indent )  {
    $fnPbarList = "..\getpbarbp\pbarbplist.txt"
    $fnTagsList = "..\getpbarbp\tagsbplist.txt"

    if ( $step.StartsWith( "step-pbar-" ) )  {
        $index = "step-pbar-".Length
        $fn = $fnPbarList
    }
    elseif ( $step.StartsWith( "step-pbtabs" ) )  {
        $index = "step-pbtabs-".Length
        $fn = $fnTagsList
    }

    if ( $fn )  {
        $arr = $step.Split( " ", [System.StringSplitOptions]::None )
        $name = $arr[0].SubString( $index )
        FindLines $fn "<step" $name | foreach {
            Write-Output "$indent$_"
        }
    }
}
function WriteSteps( [PSCustomObject] $node, [string] $indent )  {
    if ( $node -is [system.array] )  {
        Write-Output ""
        Write-Output "$indent<steps>"
        foreach ( $step in $node )  {
            if ( $step -is [String] )  {
                # Conkeyref to Persona Bar boilerplates
                if ( $step.StartsWith( "step-pb" ) )  {
                    WritePBarTags $step "$indent$tab"
                }
                # Conref to local boilerplates - step
                elseif ( $step.StartsWith( "step-" ) )  {
                    Write-Output "$indent$tab<step conref=""$conreffilelocal/$step""><cmd/></step>"
                }
                # Conref to local boilerplates - stepsection
                elseif ( $step.StartsWith( "stepsection-" ) )  {
                    Write-Output "$indent$tab<stepsection conref=""$conreffilelocal/$step""><cmd/></stepsection>"
                }
                # Literal string.
                else  {
                    Write-Output "$indent$tab<step><cmd>$step</cmd></step>"
                }
            }
            else  {
                # Not a single string, but a full structure. Process the same as the boilerplate steps.
                Write1Step4bp $step "step" "$indent$tab"
            }
        }
        Write-Output "$indent</steps>"
    }
}


function MkRellink( [PSCustomObject] $node )  {
    if ( $node.format )  {
        $format = " format=""" + $node.format + """"
    }
    if ( $node.scope )  {
        $scope = " scope=""" + $node.scope + """"
    }
    if ( $node.href )  {
        $href = " href=""" + $node.href + """"
    }
    if ( $node.text )  {
        $text = $node.text
    }
    return ( "<link $format$scope$href><linktext>$text</linktext></link>" )
}
function WriteRelLinks( [PSCustomObject] $node, [string] $indent )  {
    if ( $node )  {
        Write-Output ""
        Write-Output "	<related-links>"

        if ( $node -is [system.array] )  {
            $node | foreach  {
                $s = MkRellink $_
                Write-Output "$indent$s"
            }
        }
        elseif ( $node -is [String] )  {
            $s = MkRellink $node
            Write-Output "$indent$s"
        }
        else  {
            Write-Output "$indent$node"
        }

        Write-Output "    </related-links>"
    }
}


function WriteSection( [PSCustomObject] $node, [string] $wraptag, [string] $indent )  {
    if ( $node )  {
        Write-Output ""
        WriteStringOrArray $node $wraptag "" "$indent"
    }
}


function WriteTopic( [string] $topictype, [string] $hyph, [PSCustomObject] $node )  {
    WriteTopicStart $topictype $hyph
    $bodytag = BodyTag $topictype

    WriteTitles $node "$tab"
    WriteProlog $node "$tab"

    Write-Output ""
    Write-Output "$tab<$bodytag>"
    if ( $g_source )  { Write-Output "$tab<!-- Source: $g_source -->" }

    WriteAvail $node "$tab$tab"
    WriteSection $node.section "section" "$tab$tab"
    WritePrereq $node.prereqs "$tab$tab"
    WriteSteps $node.steps "$tab$tab"
    WriteSection $node.result  "result" "$tab$tab"
    WriteSection $node.postreq "postreq" "$tab$tab"
    WriteRelLinks $node.rellinks "$tab$tab"

    Write-Output ""
    Write-Output "$tab</$bodytag>"
    WriteTopicEnd $topictype
}


# GLOBAL VARIABLES -------------------------------------------

    $notetypes = @( "note", "important", "remember", "tip", "warning", "trouble" )


# MAIN -------------------------------------------------------

if ( $args.Count -gt 2 )  {
    $srcfn = $args[0]
    $bpfnbase = $args[1]
    $tgtdir = $args[2]

    $conreffilelocal = "$bpfnbase.dita#tsk-$bpfnbase"

    $thisscript = $MyInvocation.MyCommand.Name
    $params = [string]::Join( " ", $args )

    $myjson = Get-Content -Raw -Path $srcfn | ConvertFrom-Json

    $tab = "    "
    $indent = "$tab$tab"


    # GLOBAL -------------------------------------------------------

    foreach ( $node in $myjson.global ) {
        if ( $node.avail ) {
            $g_avail = $node.avail
        }
        if ( $node.author ) {
            $g_author = $node.author
        }
        if ( $node.audience ) { #custom object
            $g_audience = $node.audience
        }
        if ( $node.products ) { #array
            $g_products = $node.products
        }
        if ( $node.source ) {
            $g_source = $node.source
        }
    }


    # BPTEXT -------------------------------------------------------

    $tgtfile = "$tgtdir\$bpfnbase.dita"
    Write-Output "" | Out-File $tgtfile -Encoding DEFAULT

    WriteStartBP $thisscript $params $indent           | Out-File $tgtfile -Append -Encoding DEFAULT
    WriteNotes        $myjson.bpsection $indent        | Out-File $tgtfile -Append -Encoding DEFAULT
    WriteSimpletables $myjson.bptables  $indent        | Out-File $tgtfile -Append -Encoding DEFAULT
    WriteSteps4bp     $myjson.bpsteps "steps" $indent  | Out-File $tgtfile -Append -Encoding DEFAULT
    WriteEndBP $indent                                 | Out-File $tgtfile -Append -Encoding DEFAULT


    # TOPICS -------------------------------------------------------

    foreach( $topic in $myjson.topics )  {
        if ( $topic.nav )  { $hyph = Hyphenated $topic.nav }
        else               { $hyph = Hyphenated $topic.title }
        $tgtfile = "$tgtdir\$hyph.dita"

        Write-Host "Creating $tgtfile...."
        WriteTopic "task" $hyph $topic | Out-File $tgtfile -Encoding DEFAULT
    }

}

# ============================================================
