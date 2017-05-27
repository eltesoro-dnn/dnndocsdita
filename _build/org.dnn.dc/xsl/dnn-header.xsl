<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:param name="sitetitle"></xsl:param>

    <xsl:template name="gen-user-header">

        <div class="header">
            <div class="header-logo-wrapper">
				<!-- href="http://www.dnnsoftware.com/docs"> -->
				<a class="dc-dnn-logo" href="/docs"><img src="/docs/_theme/dnn_doc_center_logo.svg" onerror="this.src='/docs/_theme/dnn_doc_center_logo.png'" alt="DNN Logo" /></a>
            </div>

            <div id="header-subctr-wrapper">
                <!-- If the active subcenter must always be the first, uncomment the next line and comment out the "$sitetitle  =" lines.  -->
                <!-- <li class="subctr active"><xsl:value-of select="$sitetitle" /> -->

                <xsl:if test="$sitetitle  ='Administrators'"><div class="subctr admctr active"><a href="/docs/administrators/index.html">Administrators</a></div></xsl:if>
                <xsl:if test="$sitetitle !='Administrators'"><div class="subctr admctr"><a href="/docs/administrators/index.html">Administrators</a></div></xsl:if>

                <xsl:if test="$sitetitle  ='Content Managers'"><div class="subctr cmgctr active"><a href="/docs/content-managers/index.html">Content Managers</a></div></xsl:if>
                <xsl:if test="$sitetitle !='Content Managers'"><div class="subctr cmgctr"><a href="/docs/content-managers/index.html">Content Managers</a></div></xsl:if>

                <xsl:if test="    $sitetitle  ='Developers' or $sitetitle  ='APIs'"><div class="subctr devctr active"><a href="/docs/developers/index.html">Developers</a></div></xsl:if>
                <xsl:if test="not($sitetitle  ='Developers' or $sitetitle  ='APIs')"><div class="subctr devctr"><a href="/docs/developers/index.html">Developers</a></div></xsl:if>

                <xsl:if test="$sitetitle  ='Designers'"><div class="subctr dsgctr active"><a href="/docs/designers/index.html">Designers</a></div></xsl:if>
                <xsl:if test="$sitetitle !='Designers'"><div class="subctr dsgctr"><a href="/docs/designers/index.html">Designers</a></div></xsl:if>

                <xsl:if test="$sitetitle  ='Community Managers'"><div class="subctr modctr active"><a href="/docs/community-managers/index.html">Community Managers</a></div></xsl:if>
                <xsl:if test="$sitetitle !='Community Managers'"><div class="subctr modctr"><a href="/docs/community-managers/index.html">Community Managers</a></div></xsl:if>
            </div>

            <div class="header-nav-wrapper">
                <nav role="hamburger-home">
                    <ul class="header-nav horizontal-list">
                        <li id="header-subctr"><a href="#">Documentation</a>
                            <ul id="header-subnav-subctr">
                                <!-- If the active subcenter must always be the first, uncomment the next line and comment out the "$sitetitle  =" lines.  -->
                                <!-- <li class="subctr active"><xsl:value-of select="$sitetitle" /> -->

                                <xsl:if test="$sitetitle  ='Administrators'"><li class="subctr admctr active"><a href="/docs/administrators/index.html">Administrators</a></li></xsl:if>
                                <xsl:if test="$sitetitle !='Administrators'"><li class="subctr admctr"><a href="/docs/administrators/index.html">Administrators</a></li></xsl:if>

                                <xsl:if test="$sitetitle  ='Content Managers'"><li class="subctr cmgctr active"><a href="/docs/content-managers/index.html">Content Managers</a></li></xsl:if>
                                <xsl:if test="$sitetitle !='Content Managers'"><li class="subctr cmgctr"><a href="/docs/content-managers/index.html">Content Managers</a></li></xsl:if>

                                <xsl:if test="    $sitetitle  ='Developers' or $sitetitle  ='APIs'"><li class="subctr devctr active"><a href="/docs/developers/index.html">Developers</a></li></xsl:if>
                                <xsl:if test="not($sitetitle  ='Developers' or $sitetitle  ='APIs')"><li class="subctr devctr"><a href="/docs/developers/index.html">Developers</a></li></xsl:if>

                                <xsl:if test="$sitetitle  ='Designers'"><li class="subctr dsgctr active"><a href="/docs/designers/index.html">Designers</a></li></xsl:if>
                                <xsl:if test="$sitetitle !='Designers'"><li class="subctr dsgctr"><a href="/docs/designers/index.html">Designers</a></li></xsl:if>

                                <xsl:if test="$sitetitle  ='Community Managers'"><li class="subctr modctr active"><a href="/docs/community-managers/index.html">Community Managers</a></li></xsl:if>
                                <xsl:if test="$sitetitle !='Community Managers'"><li class="subctr modctr"><a href="/docs/community-managers/index.html">Community Managers</a></li></xsl:if>
                            </ul>
                        </li>
						<li><a href="http://www.dnnsoftware.com/community/download">Download</a></li>
						<li><a href="http://www.dnnsoftware.com/answers">Ask the Community</a></li>
						<li><a href="http://www.dnnsoftware.com/services/customer-support">Contact Support</a></li>
                    </ul>
                </nav>
            </div>

            <div><iframe src="//www.googletagmanager.com/ns.html?id=GTM-KZ2MBW" height="0" width="0" style="display:none;visibility:hidden"></iframe></div>
        </div>

    </xsl:template>

</xsl:stylesheet>

