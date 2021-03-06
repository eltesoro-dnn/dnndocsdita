<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


  <xsl:param name="sitetitle"></xsl:param>

  <!-- From org.dita.xhtml\xsl\xslhtml\dita2htmlImpl.xsl -->
  <xsl:template name="generateBreadcrumbs">
    <xsl:apply-templates select="*[contains(@class, ' topic/related-links ')]" mode="breadcrumb"/>
	<!-- DNN change: start -->
    <div>
		<xsl:attribute name="class">
			<xsl:if test="$sitetitle ='Administrators'">breadcrumbs admctr</xsl:if>
			<xsl:if test="$sitetitle ='Content Managers'">breadcrumbs cmgctr</xsl:if>
			<xsl:if test="$sitetitle ='Developers'">breadcrumbs devctr</xsl:if>
			<xsl:if test="$sitetitle ='APIs'">breadcrumbs devctr</xsl:if>
			<xsl:if test="$sitetitle ='Designers'">breadcrumbs dsgctr</xsl:if>
			<xsl:if test="$sitetitle ='Community Managers'">breadcrumbs modctr</xsl:if>
		</xsl:attribute>
		<script language="JavaScript">breadcrumbs();</script>
	</div>
	<!-- DNN change: end -->
  </xsl:template>


  <!-- DNN change: Google Custom Search Engine -->
  <!-- See https://developers.google.com/custom-search/docs/element#scope . -->
  <!-- The associated script is in scripts.js. -->
  <!-- data-resultsUrl="/docs/searchresults.html" Do not use this with the overlay style. -->
  <xsl:template name="generateSearchBox">
    <div class="searchbox">
        <div class="gcse-searchbox-only" data-gname="docs1" data-as_sitesearch="www.dnnsoftware.com" data-newWindow="true" data-enableHistory="true" data-enableAutoComplete="true" data-autoCompleteMaxCompletions="5" data-queryParameterName="q" />
    </div>
  </xsl:template>


  <!-- From org.dita.xhtml\xsl\xslhtml\dita2htmlImpl.xsl -->
  <xsl:template match="*" mode="addContentToHtmlBodyElement">
    <main role="main">
      <article role="article">
        <xsl:attribute name="aria-labelledby">
          <xsl:apply-templates select="*[contains(@class,' topic/title ')] |
                                       self::dita/*[1]/*[contains(@class,' topic/title ')]" mode="return-aria-label-id"/>
        </xsl:attribute>
        <xsl:call-template name="generateBreadcrumbs"/> <!-- DNN change: Explicitly call breadcrumbs template. -->
        <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]" mode="out-of-line"/>
        <xsl:apply-templates/> <!-- this will include all things within topic; therefore,
                               title content will appear here by fall-through
                               followed by prolog (but no fall-through is permitted for it)
                               followed by body content, again by fall-through in document order
                               followed by related links
                               followed by child topics by fall-through -->
        <xsl:call-template name="gen-endnotes"/>    <!-- include footnote-endnotes -->
        <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-endprop ')]" mode="out-of-line"/>
      </article>
    </main>
  </xsl:template>


  <!-- From org.dita.xhtml\xsl\xslhtml\dita2htmlImpl.xsl -->
  <xsl:template match="*" mode="addHeaderToHtmlBodyElement">
    <xsl:variable name="header-content" as="node()*">
      <!-- <xsl:call-template name="generateBreadcrumbs"/> DNN change: Duplicate call in the wrong place. -->
      <xsl:call-template name="gen-user-header"/>  <!-- include user's XSL running header here -->
      <xsl:call-template name="processHDR"/>
      <xsl:if test="$INDEXSHOW = 'yes'">
        <xsl:apply-templates select="/*/*[contains(@class, ' topic/prolog ')]/*[contains(@class, ' topic/metadata ')]/*[contains(@class, ' topic/keywords ')]/*[contains(@class, ' topic/indexterm ')] |
                                     /dita/*[1]/*[contains(@class, ' topic/prolog ')]/*[contains(@class, ' topic/metadata ')]/*[contains(@class, ' topic/keywords ')]/*[contains(@class, ' topic/indexterm ')]"/>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="exists($header-content)">
      <header role="banner">
        <xsl:sequence select="$header-content"/>
      </header>
    </xsl:if>
    <xsl:call-template name="generateSearchBox"/>  <!-- DNN change: Insert searchbox between header and nav. -->
  </xsl:template>


  <!-- From org.dita.xhtml\xsl\map2htmtoc\map2htmlcoverImpl.xsl. Might not be needed at all; not needed in HTML5 build. -->
  <xsl:template match="*[contains(@class, ' map/map ')]" mode="chapterBody">
    <body>
      <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]/@outputclass" mode="add-ditaval-style"/>
      <xsl:if test="@outputclass">
        <xsl:attribute name="class" select="@outputclass"/>
      </xsl:if>
      <xsl:apply-templates select="." mode="addAttributesToBody"/>
      <xsl:call-template name="setidaname"/>
      <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]" mode="out-of-line"/>
      <!-- <xsl:call-template name="generateBreadcrumbs"/> DNN change: Duplicate call in the wrong place. -->
      <xsl:call-template name="gen-user-header"/>
      <xsl:call-template name="processHDR"/>
      <xsl:if test="$INDEXSHOW = 'yes'">
        <xsl:apply-templates select="/*/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/keywords ')]/*[contains(@class, ' topic/indexterm ')]"/>
      </xsl:if>
      <xsl:call-template name="gen-user-sidetoc"/>
      <xsl:choose>
        <xsl:when test="*[contains(@class, ' topic/title ')]">
          <xsl:apply-templates select="*[contains(@class, ' topic/title ')]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="@title"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="map" as="element()*">
        <xsl:apply-templates select="." mode="normalize-map"/>
      </xsl:variable>
      <xsl:apply-templates select="$map" mode="toc"/>
      <xsl:call-template name="gen-endnotes"/>
      <xsl:call-template name="gen-user-footer"/>
      <xsl:call-template name="processFTR"/>
      <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-endprop ')]" mode="out-of-line"/>
    </body>
  </xsl:template>

  </xsl:stylesheet>
