// By Justin Whitford, from http://www.webreference.com/js/scripts/breadcrumbs/index.html
// In the header, add <script language="JavaScript" src="breadcrumbs.js"></script>
// In the breadcrumbs position, add <script language="JavaScript"><!--breadcrumbs(); --></script>

function breadcrumbs(){
    sURL = new String;
    bits = new Object;
    var x = 0;
    var stop = 0;
    var output = "<a href=\"/\">Home</a> &nbsp;&#187;&nbsp; ";
    sURL = location.href;
    sURL = sURL.slice(8,sURL.length);
    chunkStart = sURL.indexOf("/");
    sURL = sURL.slice(chunkStart+1,sURL.length)
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
        output += bits[i] + "/\">" + bits[i] + "</a> &nbsp;&#187;&nbsp; ";
    }
    document.write(output + document.title);
}
