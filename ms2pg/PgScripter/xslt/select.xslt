<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <!-- Select statement -->
  <xsl:template match="SelectStatement">
    <xsl:apply-templates select="QueryExpression" />
  </xsl:template>  

  <!-- Query -->
  <xsl:template match="QueryExpression">
    <xsl:apply-templates select="SelectElements" />
    <xsl:apply-templates select="FromClause" />
    <xsl:apply-templates select="WhereClause" />
  </xsl:template>  

  <!-- Select clause -->
  <xsl:template match="SelectElements">
    <xsl:text>SELECT </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />    
    <xsl:for-each select="SelectScalarExpression">
        <xsl:if test="position() > 1">
            <xsl:call-template name="_LineBreak" />
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="Expression" />
    </xsl:for-each>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>  

    <!-- From clause -->
    <xsl:template match="FromClause">
        <xsl:text>FROM </xsl:text>
        <xsl:call-template name="_IndentInc" />
        <xsl:call-template name="_LineBreak" />    
        <xsl:for-each select="TableReferences">
            <xsl:if test="position() > 1">
                <xsl:call-template name="_LineBreak" />
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:apply-templates select="NamedTableReference/SchemaObject" />
        </xsl:for-each>
        <xsl:call-template name="_IndentDec" />
        <xsl:call-template name="_LineBreak" />
      </xsl:template>

          <!-- From clause -->
    <xsl:template match="WhereClause">
      <xsl:text>WHERE </xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />    
      <xsl:apply-templates select="SearchCondition" />
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
    </xsl:template>

    <!-- From clause -->
    <xsl:template match="SchemaObject">
        <xsl:apply-templates select ="Identifiers" />
      </xsl:template>  
    
</xsl:stylesheet>