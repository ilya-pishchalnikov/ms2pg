<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- create index statement -->
  <xsl:template match="CreateIndexStatement">
    <xsl:text>CREATE </xsl:text>
    <xsl:if test="@Unique='True'">
      <xsl:text>UNIQUE </xsl:text>
    </xsl:if>
    <xsl:text>INDEX IF NOT EXISTS </xsl:text>
    <xsl:apply-templates select="Name/Identifier" />
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>ON </xsl:text>
    <xsl:apply-templates select="OnName/SchemaObjectName/Identifiers" />
    <xsl:text> (</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="Columns/ColumnWithSortOrder">
      <xsl:if test="position()>1">
        <xsl:text>, </xsl:text>
      <xsl:call-template name="_LineBreak" />
      </xsl:if>
    <xsl:apply-templates select="Column/ColumnReferenceExpression/MultiPartIdentifier" />        
    <xsl:if test="@SortOrder='Ascending'">
        <xsl:text> ASC</xsl:text>
      </xsl:if>
    <xsl:if test="@SortOrder='Descending'">
        <xsl:text> DESC</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>)</xsl:text>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:if test="IncludeColumns/node()">
      <xsl:text>INCLUDE (</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="IncludeColumns/ColumnReferenceExpression">
        <xsl:if test="position()>1">
          <xsl:call-template name="_LineBreak" />
          <xsl:text>, </xsl:text>
        </xsl:if>
          <xsl:apply-templates select="MultiPartIdentifier" />
      </xsl:for-each>
      <xsl:call-template name="_IndentDec" />
          <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>
      <xsl:call-template name="_IndentDec" />
    </xsl:if>
    <xsl:if test="FilterPredicate/node()">
      <xsl:call-template name="_LineBreak" />
      <xsl:text>WHERE </xsl:text>
      <xsl:apply-templates select="FilterPredicate/Expression" />
    </xsl:if>
    <xsl:call-template name="_IndentDec" />
  </xsl:template>
</xsl:stylesheet>