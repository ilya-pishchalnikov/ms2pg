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
    <xsl:apply-templates select="GroupByClause" />
    <xsl:apply-templates select="HavingClause" />
    <xsl:apply-templates select="OrderByClause" />
  </xsl:template>  

  <!-- Select clause -->
  <xsl:template match="SelectElements">
    <xsl:text>SELECT </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" /> 
    <xsl:for-each select="*">
      <xsl:if test="position() > 1">
        <xsl:call-template name="_LineBreak" />
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="local-name()='SelectScalarExpression'">
          <xsl:apply-templates select="Expression" />
        </xsl:when>
        <xsl:when test="local-name()='SelectSetVariable'">
          <xsl:apply-templates select="Expression" />
        </xsl:when>
        <xsl:when test="local-name()='SelectStarExpression'">
          <xsl:text>*</xsl:text>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      <xsl:if test="ColumnName/node()">
        <xsl:text> AS </xsl:text>
        <xsl:apply-templates select="ColumnName/Identifier" />
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="SelectSetVariable">
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>INTO</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" /> 
      <xsl:for-each select="SelectSetVariable">
        <xsl:apply-templates select="Variable" />
      </xsl:for-each>
    </xsl:if>
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

    <!-- Group by clause -->
    <xsl:template match="GroupByClause">
      <xsl:text>GROUP BY </xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" /> 
      <xsl:for-each select="GroupingSpecifications/ExpressionGroupingSpecification">
        <xsl:if test="position() > 1">
          <xsl:call-template name="_LineBreak" />
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="Expression" />
      </xsl:for-each>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
    </xsl:template>


    <!-- Having clause -->
    <xsl:template match="HavingClause">
      <xsl:text>HAVING </xsl:text>
      <xsl:apply-templates select="SearchCondition" />
      <xsl:call-template name="_LineBreak" />
    </xsl:template>

    <!-- Order by clause -->
    <xsl:template match="OrderByClause">
      <xsl:text>ORDER BY </xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" /> 
      <xsl:for-each select="OrderByElements/ExpressionWithSortOrder">
        <xsl:if test="position() > 1">
          <xsl:call-template name="_LineBreak" />
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="Expression" />
        <xsl:choose>
          <xsl:when test="@SortOrder='Ascending'">
            <xsl:text> ASC </xsl:text>
          </xsl:when>
          <xsl:when test="@SortOrder='Descending'">
            <xsl:text> DESC </xsl:text>
          </xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
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
            <xsl:when test="NamedTableReference">
              <xsl:for-each select="NamedTableReference">
                <xsl:if test="position() > 1">
                  <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="SchemaObject" />
                <xsl:if test="Alias">
                  <xsl:text> AS </xsl:text>
                  <xsl:value-of select="Alias/@Value"></xsl:value-of>
                </xsl:if>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>/*UNKNOWN TABLE REFERENCE*/</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:for-each>
    </xsl:template>

    <xsl:template match="NamedTableReference|FirstTableReference[not(@QualifiedJoinType)]|SecondTableReference[not(@QualifiedJoinType)]">
     <xsl:choose>
        <xsl:when test="SchemaObject">
          <xsl:apply-templates select="SchemaObject" />
        </xsl:when>
        <xsl:when test="QueryExpression">
          <xsl:text>(</xsl:text>
          <xsl:call-template name="_IndentInc" />
          <xsl:call-template name="_IndentInc" />
          <xsl:call-template name="_LineBreak" />
          <xsl:apply-templates select="QueryExpression" />
          <xsl:call-template name="_IndentDec" />
          <xsl:call-template name="_LineBreak" />
          <xsl:text>)</xsl:text>
          <xsl:call-template name="_IndentDec" />
        </xsl:when>
        <xsl:when test="FirstTableReference|SecondTableReference">
          <xsl:call-template name="_IndentInc" />
          <xsl:call-template name="_LineBreak" />
          <xsl:apply-templates select="*" />
          <xsl:call-template name="_IndentDec" />
          <xsl:call-template name="_LineBreak" />
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
    <xsl:template match="QualifiedJoin|UnqualifiedJoin|FirstTableReference[@QualifiedJoinType]|SecondTableReference[@QualifiedJoinType]">
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

    <xsl:template match="Subquery">
      <xsl:text>(</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />    
      <xsl:apply-templates select="QueryExpression" />
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>
      <xsl:call-template name="_IndentDec" />
    </xsl:template>

    <!-- From clause -->
    <xsl:template match="SchemaObject">
        <xsl:apply-templates select ="Identifiers" />
      </xsl:template>  
    
</xsl:stylesheet>