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



// Emolytics.com - feedback app
var getsmily_id="6gtee4abmwbh83n";
(function(d) {
    var gs=d.createElement("script");
    var gsf=d.getElementsByTagName("script")[0];
    gs.async=1;
    gs.src="https://cdn.emolytics.com/script/emolytics-widget.js";
    gsf.parentNode.insertBefore(gs,gsf);
})(document);



// Slideshow
// Source: http://www.w3schools.com/w3css/w3css_slideshow.asp
var slideIndex = 1;
showDivs(slideIndex);
function plusDivs(n) {
    showDivs(slideIndex += n);
}
function showDivs(n) {
    var i;
    var x = document.getElementsByClassName("mySlides");
    if (n > x.length) {slideIndex = 1}
    if (n < 1) {slideIndex = x.length} ;
    for (i = 0; i < x.length; i++) {
        x[i].style.display = "none";
    }
    x[slideIndex-1].style.display = "block";
}



// Carousel
// Source: http://www.w3schools.com/w3css/w3css_slideshow.asp
var carouselIndex = 0;
carousel();
function carousel() {
    var i;
    var x = document.getElementsByClassName("mySlides");
    for (i = 0; i < x.length; i++) {
      x[i].style.display = "none";
    }
    carouselIndex++;
    if (carouselIndex > x.length) {carouselIndex = 1}
    x[carouselIndex-1].style.display = "block";
    setTimeout(carousel, 2000); // Change image every 2 seconds
}
