<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template name="gen-user-header">

        <div class="header">
            <h1>
                <a class="logo" href="http://www.dnnsoftware.com/docs">
                    <img src="http://dnnsoftware.com/docs/_static/DNN_logo_28px.png" alt="DNN Logo" />
                    Documentation Center
                </a>
            </h1>
            <!-- <button class="navbar-toggle" aria-expanded="false">
                <span class="sr-only">Toggle navigation</span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="close-nav">X</span>
            </button> -->
        </div>

        <!--
        <div class="header {% if theme_navbar_fixed_top|tobool -%} navbar-fixed-top{%- endif -%}">
            <div class="col-md-4 col-xs-12 logo-wrapper">
                <a class="logo" href="{{ theme_site_home }}">
                    {%- block sidebarlogo %}
                        {%- if logo %}
                        <img src="{{ pathto('_static/' + logo, 1) }}" alt="DNN Logo" />
                        {%- endif %}
                    {%- endblock %}
                    {% if theme_navbar_title -%}
                        <span>{{ theme_navbar_title|e }}</span>
                    {%- else -%}
                        {{ project|e }}
                    {%- endif -%}
                </a>
                <button class="navbar-toggle" aria-expanded="false">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="close-nav">X</span>
                </button>
            </div>
            <div class="col-md-8 col-xs-12 nav-wrapper">
                <nav class="nav">
                    <ul class="nav-main-level">
                        {% if theme_navbar_links %}
                            {% include "navbarlinks.html" %}
                        {% endif %}
                    </ul>
                </nav>
            </div>
        </div>
        -->

    </xsl:template>

</xsl:stylesheet>

