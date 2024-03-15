<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:import href="settings.xslt" />
  <xsl:import href="common.xslt" />
  <xsl:import href="createtable.xslt" />
  <xsl:import href="statements.xslt" />
  <xsl:import href="datatypes.xslt" />
  <xsl:import href="altertable.xslt" />
  <xsl:import href="createindex.xslt" />
  <xsl:import href="createview.xslt" />
  <xsl:import href="select.xslt" />
  
  
  <xsl:output method="text" omit-xml-declaration="yes"/>
  
  <!-- =================================== ТОЧКА ВХОДА =================================== -->
  <xsl:template match="/">
    <xsl:for-each select="TSqlScript/Batches/TSqlBatch/.">
      <xsl:call-template name="_Statements"/>
      <xsl:call-template name="_LineBreak"/>
      <xsl:text>/*GO*/</xsl:text>
      <xsl:call-template name="_LineBreak"/>
    </xsl:for-each>
  </xsl:template> 
  
</xsl:stylesheet>