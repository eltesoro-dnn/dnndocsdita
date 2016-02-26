<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:param name="sitetitle"></xsl:param>

    <xsl:template name="gen-user-header">

        <div class="header">
            <div class="header-logo-wrapper">
                <a class="logo" href="http://www.dnnsoftware.com/docs">
                    <img src="/_theme/DNN_logo_28px.png" alt="DNN Logo" />
                </a>
                <div class="site-title">
                    <xsl:if test="$sitetitle ='Administrator Center' " >
                        <a href="/admin/AdmCtr.html">Administrator Center</a>
                    </xsl:if>
                    <xsl:if test="$sitetitle ='Developer Center' " >
                        <a href="/dev/DevCtr.html">Developer Center</a>
                    </xsl:if>
                    <xsl:if test="$sitetitle ='Designer Center' " >
                        <a href="/design/DsgCtr.html">Designer Center</a>
                    </xsl:if>

                    <div class="sibling-sites">
                        <ul>
                            <xsl:if test="$sitetitle !='Administrator Center' " >
                                <li><a href="/admin/AdmCtr.html">Administrator Center</a></li>
                            </xsl:if>
                            <xsl:if test="$sitetitle !='Developer Center' " >
                                <li><a href="/dev/DevCtr.html">Developer Center</a></li>
                            </xsl:if>
                            <xsl:if test="$sitetitle !='Designer Center' " >
                                <li><a href="/design/DsgCtr.html">Designer Center</a></li>
                            </xsl:if>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="header-nav-wrapper">
                <nav>
                    <ul class="header-nav horizontal-list">
                        <li><a href="http://www.dnnsoftware.com/community/download">Download</a></li>
                        <li><a href="http://www.dnnsoftware.com/services/customer-support/success-network">Evoq Support</a></li>
                        <li>Community
                            <ul id="navcommunity" class="subnav">
                                <li><a href="http://www.dnnsoftware.com/community-blog">Blog</a></li>
                                <li><a href="http://www.dnnsoftware.com/forums">Forums</a></li>
                                <li><a href="http://www.dnnsoftware.com/forge">Forge</a></li>
                            </ul>
                        </li>
                    </ul>
                </nav>
            </div>
        </div>

    </xsl:template>

</xsl:stylesheet>

