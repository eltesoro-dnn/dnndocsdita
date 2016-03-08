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
                <xsl:choose>
                    <xsl:when test="$sitetitle ='admctr'">
                        <div class="active">Administrators</div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div><a href="/adm/AdmCtr.html">Administrators</a></div>
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:choose>
                    <xsl:when test="$sitetitle ='devctr'">
                        <div class="active">Developers</div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div><a href="/dev/DevCtr.html">Developers</a></div>
                    </xsl:otherwise>
                </xsl:choose>

                <xsl:choose>
                    <xsl:when test="$sitetitle ='dsgctr'">
                        <div class="active">Designers</div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div><a href="/dsg/DsgCtr.html">Designers</a></div>
                    </xsl:otherwise>
                </xsl:choose>
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

