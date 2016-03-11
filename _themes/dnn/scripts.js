$(document).ready(function() {

    // alert("Your book is overdue.");

    // adjust the HTML rendered by Sphinx for the TOC
    $('nav[role="toc"] > ul')
        .attr({
            id: 'articleNavAffix',
            class: 'affix-top'
        })
        .children('li')
        .children()
        .siblings('ul')
        .addClass('nav-tabs')
        .children('li')
        .children()
        .siblings('ul')
        .children('li')
        .addClass('sub-nav-tabs');

    var openElement = $('nav[role="toc"]').find('.active');

    openMenuItemOnLoad(openElement);

    // add triangle to parents
    $("nav[role='toc'] > ul > li").each(function(){
        if($(this).has("ul").length){
            $(this).addClass('toc-aria-arrow-closed');
        };
    })

    // add triangle to children that have children
    $("nav[role='toc'] > ul > li > ul > li").each(function(){
        if($(this).has("ul").length){
            $(this).addClass('toc-aria-arrow-closed');
        };
    })

    // click to slide toggle the menus
    $(function () {
        $('nav[role="toc"] > ul').find('li').each(function(){
            $(this).click(function() {
            openMenuItem(this);
            event.stopPropagation();
            });
        });

    });

    // open menus and rotate arrows with a slide toggle/toggle class
    function openMenuItem(element){
        $(element).children('ul').slideToggle('fast', function() {
            $(this).parent('li').toggleClass('toc-aria-arrow-open', $(this).is(':visible'));
        });
    };

    function openMenuItemOnLoad(element){
        $(element).children('ul').slideToggle('fast', function() {
            $(this).parent('li').toggleClass('toc-aria-arrow-open', $(this).is(':visible'));
        });

        $(element).parents('li').addClass('toc-aria-arrow-open').children('ul').slideToggle();
    }

    // remove the arrow from glossary
    $( "nav[role='toc'] > ul >li > ul > li" ).last().removeClass( "toc-aria-arrow-closed" );

});



(function($) {

  $.fn.menumaker = function(options) {

      var cssmenu = $(this), settings = $.extend({
        title: "",
        format: "accordion",
        sticky: false
      }, options);

      return this.each(function() {
        cssmenu.prepend('<div id="menu-button">' + settings.title + '</div>');
        $(this).find("#menu-button").on('click', function(){
          $(this).toggleClass('menu-opened');
          var mainmenu = $(this).next('ul');
          if (mainmenu.hasClass('open')) {
            mainmenu.hide().removeClass('open');
          }
          else {
            mainmenu.show().addClass('open');
            if (settings.format === "dropdown") {
              mainmenu.find('ul').show();
            }
          }
        });

        cssmenu.find('li ul').parent().addClass('has-sub');

        multiTg = function() {
          cssmenu.find(".has-sub").prepend('<span class="submenu-button"></span>');
          cssmenu.find('.submenu-button').on('click', function() {
            $(this).toggleClass('submenu-opened');
            if ($(this).siblings('ul').hasClass('open')) {
              $(this).siblings('ul').removeClass('open').hide();
            }
            else {
              $(this).siblings('ul').addClass('open').show();
            }
          });
        };

        if (settings.format === 'multitoggle') multiTg();
        else cssmenu.addClass('dropdown');

        if (settings.sticky === true) cssmenu.css('position', 'fixed');

        resizeFix = function() {
          if ($( window ).width() > 992) {
            // cssmenu.find('ul').show();

            // show nav menu drop downs on hover toggle
            $(".site-subtitle").hover(function () {
                $(".sibling-sites").toggle();
            })
            $("#header-askq").hover(function () {
                $(this).find('ul').toggle();
            })
          }

          if ($(window).width() <= 992) {
            // cssmenu.find('ul').hide().removeClass('open');
          }
        };
        resizeFix();
        return $(window).on('resize', resizeFix);

      });
  };
})(jQuery);

(function($){
$(document).ready(function(){

$("nav[role='hamburger-home']").menumaker({
   title: "",
   format: "multitoggle"
});

});
})(jQuery);