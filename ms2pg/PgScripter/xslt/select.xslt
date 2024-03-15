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
        <xsl:if test="ColumnName/node()">
          <xsl:text> AS </xsl:text>
          <xsl:apply-templates select="ColumnName/Identifier" />
        </xsl:if>
    </xsl:for-each>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>  

    <!-- From clause -->
    <xsl:template match="FromClause">
      <xsl:text>FROM </xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" /> 
      <xsl:apply-templates select="TableReferences" /> 
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
    </xsl:template>

    <xsl:template match="TableReferences">
      <xsl:for-each select=".">
          <xsl:choose>
            <xsl:when test="QualifiedJoin">
              <xsl:apply-templates select="QualifiedJoin" />
            </xsl:when>
            <xsl:when test="UnqualifiedJoin">
              <xsl:apply-templates select="UnqualifiedJoin" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>/*UNKNOWN TABLE REFERENCE*/</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          
      </xsl:for-each>
    </xsl:template>

    <xsl:template match="NamedTableReference|FirstTableReference|SecondTableReference">
      <xsl:choose>
        <xsl:when test="SchemaObject">
          <xsl:apply-templates select="SchemaObject" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>/*Unknown table reference*/</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="NamedTableReference/SchemaObject" />
      <xsl:if test="Alias">
        <xsl:text> AS </xsl:text>
        <xsl:value-of select="Alias/@Value"></xsl:value-of>
      </xsl:if>
    </xsl:template>

    <!-- Join clause -->
    <xsl:template match="QualifiedJoin|UnqualifiedJoin">
      <xsl:apply-templates select ="FirstTableReference" />
      <xsl:call-template name="_LineBreak" />
      <xsl:choose>
        <xsl:when test="@QualifiedJoinType='LeftOuter'">
          <xsl:text>LEFT </xsl:text>
        </xsl:when>
        <xsl:when test="@QualifiedJoinType='RightOuter'">
          <xsl:text>RIGHT </xsl:text>
        </xsl:when>
        <xsl:when test="@QualifiedJoinType='FullOuter'">
          <xsl:text>FULL </xsl:text>
        </xsl:when>
        <xsl:when test="@UnqualifiedJoinType='CrossJoin'">
          <xsl:text>CROSS </xsl:text>
        </xsl:when>
        <xsl:when test="@QualifiedJoinType='Inner'">
          <xsl:text>INNER </xsl:text>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      <xsl:text>JOIN </xsl:text>
      <xsl:apply-templates select ="SecondTableReference" />
      <xsl:if test="SearchCondition">
        <xsl:text> ON </xsl:text>
        <xsl:apply-templates select="SearchCondition" />
      </xsl:if>
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