<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template match="/|node()|@*" mode="gen-user-head">
            <script language="JavaScript" src="/docs/_theme/headscripts.js"></script>
            <meta name="viewport" content="width=device-width, initial-scale=1"></meta>
    </xsl:template>

</xsl:stylesheet>

