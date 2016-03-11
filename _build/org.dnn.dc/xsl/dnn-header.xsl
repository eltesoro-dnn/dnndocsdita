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
            <div class="header-nav-wrapper">
                <nav role="hamburger-home">

                    <ul class="header-nav horizontal-list">
                        <li id="header-subctr"><a href="#">Documentation</a>
                            <ul id="header-subnav-subctr">
                                <li class="subctr active">
                                    <!-- Use the next line, if the active subcenter must always be the first. -->
                                    <!-- <xsl:value-of select="$sitetitle" /> -->

                                    <!-- Use the next three lines, if the subcenters must always be listed in the same order. -->
                                    <xsl:if test="$sitetitle  ='Administrators'"><a href="/Administrators/index.html">Administrators</a></xsl:if>
                                    <xsl:if test="$sitetitle  ='Developers'"><a href="/Developers/index.html">Developers</a></xsl:if>
                                    <xsl:if test="$sitetitle  ='Designers'"><a href="/Designers/index.html">Designers</a></xsl:if>
                                </li>

                                <!-- The non-active subcenters are always listed in the same order. -->
                                <xsl:if test="$sitetitle !='Administrators'"><li class="subctr"><a href="/Administrators/index.html">Administrators</a></li></xsl:if>
                                <xsl:if test="$sitetitle !='Developers'"><li class="subctr"><a href="/Developers/index.html">Developers</a></li></xsl:if>
                                <xsl:if test="$sitetitle !='Designers'"><li class="subctr"><a href="/Designers/index.html">Designers</a></li></xsl:if>
                            </ul>
                        </li>
                        <li><a href="http://www.dnnsoftware.com/community/download">Download</a></li>
                        <li id="header-askq"> <a href="#">Ask a Question</a>
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

