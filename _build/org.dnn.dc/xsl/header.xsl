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
                    Documentation Center for
                    <div class="site-subtitle">
                        <xsl:if test="$sitetitle ='Administrator Center' " >
                            <a href="/admin/AdmCtr.html">Administrators</a>
                        </xsl:if>
                        <xsl:if test="$sitetitle ='Developer Center' " >
                            <a href="/dev/DevCtr.html">Developers</a>
                        </xsl:if>
                        <xsl:if test="$sitetitle ='Designer Center' " >
                            <a href="/design/DsgCtr.html">Designers</a>
                        </xsl:if>

                        <div class="sibling-sites">
                            <ul>
                                <xsl:if test="$sitetitle !='Administrator Center' " >
                                    <li><a href="/admin/AdmCtr.html">Administrators</a></li>
                                </xsl:if>
                                <xsl:if test="$sitetitle !='Developer Center' " >
                                    <li><a href="/dev/DevCtr.html">Developers</a></li>
                                </xsl:if>
                                <xsl:if test="$sitetitle !='Designer Center' " >
                                    <li><a href="/design/DsgCtr.html">Designers</a></li>
                                </xsl:if>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
            <div class="header-nav-wrapper">
                <nav>
                    <ul class="header-nav horizontal-list">
                        <li><a href="http://www.dnnsoftware.com/community/download">Download</a></li>
                        <li>Ask a question
                            <ul>
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

