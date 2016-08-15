$(document).ready(function() {

    $(window).on('resize', function () {
        if ($(window).width() > 976) {
            $('ul.header-nav').show();
        } else {
            $('ul.header-nav').hide();
        }
    });

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

    // set active class to parent
    // $(function() {
    //     var pgurl = window.location.pathname.substr(1);
    //      $("nav[role='toc'] ul li a").each(function(){
    //             var tmpUrl = $(this).attr("href").replace('../..','').replace('../','');
    //             if (tmpUrl.indexOf('/') == 0) {
    //                 tmpUrl = tmpUrl.substr(1);
    //             }
    //          if(tmpUrl == pgurl || tmpUrl == '' ){
    //           $(this).parent('li').addClass("active");
    //           openMenuItemOnLoad($(this).parent('li'));
    //         }
    //      })
    // });

    // add triangle to parents
    $("nav[role='toc'] > ul > li, nav[role='toc'] > ul > li > ul > li, nav[role='toc'] > ul > li > ul > li > ul > li, nav[role='toc'] > ul > li > ul > li > ul > li > ul > li, nav[role='toc'] > ul > li > ul > li > ul > li > ul > li > ul > li").each(function(){
        if($(this).has("ul").length){
            $(this).addClass('toc-aria-arrow-closed');
        };
    })

    // click to slide toggle the menus
    $(function () {
        $('nav[role="toc"] > ul').find('li').each(function(){
            $(this).click(function(e) {
            openMenuItem(this);
            e.stopPropagation();
            });
        });
    });

    var openElement = $('nav[role="toc"]').find('.active');

    openMenuItemOnLoad(openElement);

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

    $("nav[role='hamburger-home']").mymenu({
       title: "",
       format: "multitoggle"
    });

    // remove Search Documentation on click
    $(".searchbox-home").click(function() {
        $("p#dc-search-documentation-dummy").fadeOut('fast');
        $(":input").select();
    });

});

// hamburger menu

(function($) {

  $.fn.mymenu = function(options) {

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
            $('#dc-hamburger-white-box').hide();
          }
          else {
            mainmenu.show().addClass('open');
            $('#dc-hamburger-white-box').show();
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
          if ($( window ).width() > 976) {
            $("nav[role='toc']").show();
          }

          if ($(window).width() <= 976) {
          	$("nav[role='toc']").hide();
          }
        };
        resizeFix();
        return $(window).on('resize', resizeFix);

      });
  };
})(jQuery);