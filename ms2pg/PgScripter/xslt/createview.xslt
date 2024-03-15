<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Create view statement -->
  <xsl:template match="CreateViewStatement">
    <xsl:text>CREATE OR REPLACE VIEW </xsl:text>
    <xsl:apply-templates select="SchemaObjectName" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>AS</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="SelectStatement" />
  </xsl:template>  

</xsl:stylesheet>