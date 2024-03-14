<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 <!-- Statements choose -->
  <xsl:template name="_Statements">
    <xsl:for-each select="Statements/*">
      <xsl:call-template name="_StatementBegin" />
      <xsl:choose>
        <xsl:when test="local-name() = 'UseStatement'">
          <xsl:text>/*USE STATEMENT*/</xsl:text>
        </xsl:when>
        <xsl:when test="local-name() = 'PredicateSetStatement'">
          <xsl:apply-templates select ="." />
        </xsl:when>
        <xsl:when test="local-name() = 'CreateTableStatement'">
          <xsl:apply-templates select = "." />
        </xsl:when>
        <xsl:when test="local-name() = 'UpdateStatisticsStatement'">
          <xsl:apply-templates select = "." />
        </xsl:when>
        <xsl:when test="local-name() = 'AlterTableAddTableElementStatement'">
          <xsl:apply-templates select = "." />
        </xsl:when>
        <xsl:when test="local-name() = 'CreateIndexStatement'">
          <xsl:apply-templates select = "." />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name ="_UnknownToken" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="_EndOfStatement" />
      <xsl:call-template name="_StatementEnd" />
    </xsl:for-each>
  </xsl:template>
  
  <!-- Set options statement -->
  <xsl:template match="PredicateSetStatement">
    <xsl:text>/*SET </xsl:text>
    <xsl:value-of select="@Options"/>
    <xsl:choose>
      <xsl:when test="@IsOn='True'">
        <xsl:text> ON</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text> OFF</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>*/</xsl:text>
  </xsl:template>  

  <!-- Update statistics (Analyze) statement -->
  <xsl:template match="UpdateStatisticsStatement">
    <xsl:text>ANALYZE </xsl:text>
    <xsl:apply-templates select="SchemaObjectName" />
  </xsl:template>

    <!-- Update statistics (Analyze) statement -->
    <xsl:template match="CreateIndexStatement">
      <xsl:text>CREATE </xsl:text>
      <xsl:if test="@Unique='True'">
        <xsl:text>UNIQUE </xsl:text>
      </xsl:if>
      <xsl:text>INDEX IF NOT EXISTS </xsl:text>
      <xsl:value-of select="Name/@Value"></xsl:value-of>
      <xsl:text> ON </xsl:text>
      <xsl:apply-templates select="OnName/Identifiers" />
      <xsl:text>(</xsl:text>
      <xsl:for-each select="Columns/ColumnWithSortOrder">
        <xsl:if test="position()>1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="Column/MultiPartIdentifier" />        
        <xsl:if test="@SortOrder='Ascending'">
          <xsl:text> ASC</xsl:text>
        </xsl:if>
        <xsl:if test="@SortOrder='Descending'">
          <xsl:text> DESC</xsl:text>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>)</xsl:text>
    </xsl:template>

</xsl:stylesheet>