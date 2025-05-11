<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:import href="settings.xslt" />
  <xsl:import href="common.xslt" />
	
  <xsl:output method="text" omit-xml-declaration="yes"/>
  
  <!-- =================================== ENTRY POINT =================================== -->
  <xsl:template match="/">
    <xsl:for-each select="TSqlScript/ScriptTokenStream/TSqlParserToken">
		<xsl:value-of select="@Text"/>
    </xsl:for-each>
  </xsl:template> 
  
</xsl:stylesheet>