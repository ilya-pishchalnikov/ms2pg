﻿<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
  >
  <xsl:output method="xml" indent="yes"/>
  
  <xsl:template match="node()|@*" name="identity">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
      <xsl:message>dlkjfal</xsl:message>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
