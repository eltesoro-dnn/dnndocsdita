<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:param name="sitetitle"></xsl:param>

    <xsl:template name="gen-user-header">

        <div class="header">
            <div class="header-logo-wrapper">
                <a class="logo" href="/"> <!-- href="http://www.dnnsoftware.com/docs"> -->
                    <img src="/_theme/DNN_logo_28px.png" alt="DNN Logo" />
                </a>
                <div class="site-title">Documentation Center</div>
            </div>
            <div class="header-subcenters">
                <div class="active"><xsl:value-of select="$sitetitle" /></div>
                <!--
                <xsl:if test="$sitetitle  ='Administrators'"><div class="active"><a href="/Administrators/index.html">Administrators</a></div></xsl:if>
                <xsl:if test="$sitetitle  ='Developers'"><div class="active"><a href="/Developers/index.html">Developers</a></div></xsl:if>
                <xsl:if test="$sitetitle  ='Designers'"><div class="active"><a href="/Designers/index.html">Designers</a></div></xsl:if>
                -->

                <xsl:if test="$sitetitle !='Administrators'"><div><a href="/Administrators/index.html">Administrators</a></div></xsl:if>
                <xsl:if test="$sitetitle !='Developers'"><div><a href="/Developers/index.html">Developers</a></div></xsl:if>
                <xsl:if test="$sitetitle !='Designers'"><div><a href="/Designers/index.html">Designers</a></div></xsl:if>
            </div>
            <div class="header-nav-wrapper">
                <nav>
                    <ul class="header-nav horizontal-list">
                        <li><a href="http://www.dnnsoftware.com/community/download">Download</a></li>
                        <li id="header-askq">Ask a question
                            <ul id="header-subnav-support">
                                <li><a href="http://www.dnnsoftware.com/answers">about DNN Platform</a></li>
                                <li><a href="http://www.dnnsoftware.com/services/customer-support">about DNN Evoq</a></li>
                            </ul>
                        </li>
                    </ul>
                </nav>
            </div>
        </div>

    </xsl:template>

</xsl:stylesheet>

