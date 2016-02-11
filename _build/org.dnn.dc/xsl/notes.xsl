<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template match="*" mode="process.note.common-processing">

        <xsl:param name="type" select="@type"/>

        <xsl:param name="title">
            <xsl:call-template name="getVariable">
                <xsl:with-param name="id" select="concat(upper-case(substring($type, 1, 1)), substring($type, 2))"/>
            </xsl:call-template>
        </xsl:param>

        <div>
            <xsl:call-template name="commonattributes">

                <!-- From dita2html5Impl.xsl: -->
                <xsl:with-param name="default-output-class" select="string-join(($type, concat('note_', $type)), ' ')"/>

                <!-- From dita2htmlImpl.xsl:
                <xsl:with-param name="default-output-class" select="$type"/>
                 -->

            </xsl:call-template>

            <xsl:call-template name="setidaname"/>

            <!-- Normal flags go before the generated title; revision flags only go on the content. -->
            <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]/prop" mode="ditaval-outputflag"/>

            <!-- Deprecated since 2.2: {$type}title is for backwards compatibility -->
            <p class="note__title">
                <xsl:copy-of select="$title"/>
            </p>

            <xsl:text />
            <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-startprop ')]/revprop" mode="ditaval-outputflag"/>
            <xsl:apply-templates/>
            <!-- Normal end flags and revision end flags both go out after the content. -->
            <xsl:apply-templates select="*[contains(@class, ' ditaot-d/ditaval-endprop ')]" mode="out-of-line"/>
        </div>

    </xsl:template>

</xsl:stylesheet>
