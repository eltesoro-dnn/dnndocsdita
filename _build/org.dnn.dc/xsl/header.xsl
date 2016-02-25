<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template name="gen-user-header">

        <div class="header">
            <div class="header-logo-wrapper">
                <a class="logo" href="http://www.dnnsoftware.com/docs">
                    <img src="http://dnnsoftware.com/docs/_static/DNN_logo_28px.png" alt="DNN Logo" />
                    <div id="site-title">Documentation Center</div>
                </a>
            </div>
            <div class="header-nav-wrapper">
                <nav>
                    <!--
                    <ul class="header-nav horizontal-list">
                        <li><a href="http://www.dnnsoftware.com/community/download">Download</a></li>
                        <li><a href="http://www.dnnsoftware.com/services/customer-support">Support</a></li>
                        <li>Community
                            <ul id="navcommunity" class="subnav">
                                <li><a href="http://www.dnnsoftware.com/community-blog">Blog</a></li>
                                <li><a href="http://www.dnnsoftware.com/forums">Forums</a></li>
                                <li><a href="http://www.dnnsoftware.com/forge">Forge</a></li>
                            </ul>
                        </li>
                    </ul>
                    -->
                    <!-- From Joe's version -->
                    <ul class="header-nav horizontal-list">
                        <li id="toc-doc">Documentation
                            <ul id="header-subnav-documentation">
                                <li><a href="/admin/AdmCtr.html">Admin</a></li>
                                <li><a href="/dev/DevCtr.html">Developer</a></li>
                                <li><a href="/design/DsgCtr.html">Designer</a></li>
                            </ul>
                        </li>
                        <li><a href="http://www.dnnsoftware.com/community-blog">Blogs</a></li>
                        <li><a href="http://www.dnnsoftware.com/community/download">Download</a></li>
                        <li id="toc-sup">Support
                            <ul id="header-subnav-support">
                                <li><a href="http://www.dnnsoftware.com/forums">Forums</a></li>
                                <li><a href="http://www.dnnsoftware.com/services/customer-support/success-network">Evoq Success Network</a></li>
                            </ul>
                        </li>
                    </ul>
                </nav>
            </div>
        </div>

    </xsl:template>

</xsl:stylesheet>

