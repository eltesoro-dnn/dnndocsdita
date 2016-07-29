// By Justin Whitford, from http://www.webreference.com/js/scripts/breadcrumbs/index.html
// In the header, add <script language="JavaScript" src="breadcrumbs.js"></script>
// In the breadcrumbs position, add <script language="JavaScript"><!--breadcrumbs(); --></script>

function breadcrumbs(){
    sDivider = "&#187;";
    sRoot = new String( "/docs" );
    sURL = new String;
    bits = new Object;
    var x = 0;
    var stop = 0;
    var output = "<a href=\"/docs\">Home</a> &nbsp;" + sDivider + "&nbsp; ";
    sURL = location.href;
    sURL = sURL.slice(8,sURL.length);
    chunkStart = sURL.indexOf(sRoot);
    sURL = sURL.slice(chunkStart+sRoot.length+1,sURL.length)
    while(!stop){
        chunkStart = sURL.indexOf("/");
        if (chunkStart != -1){
            bits[x] = sURL.slice(0,chunkStart)
            sURL = sURL.slice(chunkStart+1,sURL.length);
        }else{
            stop = 1;
        }
        x++;
    }
    for(var i in bits){
        output += "<a href=\"";
        for(y=1;y<x-i;y++){
            output += "../";
        }
        output += bits[i] + "/\">" + bits[i].replace( /-/g, " " ) + "</a> &nbsp;" + sDivider + "&nbsp; ";
    }
    document.write(output + document.title);
}



// Google Custom Search Engine

(function() {
    var cx = '013510249882471164181:tip1lg7hloc';   // for live site
    // var cx = '013510249882471164181:zacnxv7uabo';   // for the staging server
    var gcse = document.createElement('script');
    gcse.type = 'text/javascript';
    gcse.async = true;
    gcse.src = (document.location.protocol == 'https:' ? 'https:' : 'http:') +
        '//cse.google.com/cse.js?cx=' + cx;
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(gcse, s);
})();
