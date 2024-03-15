<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
>
  <xsl:import href="settings.xslt" />
  <xsl:output omit-xml-declaration="yes" indent="yes" />


  <!-- Сообщение о неизвестном узле -->
  <xsl:template name="_UnknownToken">
    <xsl:call-template name="_LineBreak" />
    <xsl:text>/********************** UNKNOWN TOKEN '</xsl:text>
    <xsl:value-of select="local-name()" />
    <xsl:text>'**********************/</xsl:text>
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!-- Increment indent -->
  <xsl:template name="_IndentInc">
    <xsl:text>{{Indent++}}</xsl:text>
  </xsl:template>

  <!-- Decrement indent -->
  <xsl:template name="_IndentDec">
    <xsl:text>{{Indent--}}</xsl:text>
  </xsl:template>

  <!-- Statement begin mark -->
  <xsl:template name="_StatementBegin">
    <xsl:text>{{StatementBegin:</xsl:text>
    <xsl:value-of select="local-name()" />
    <xsl:text>}}</xsl:text>
  </xsl:template>

  <!-- Statement end mark -->
  <xsl:template name="_StatementEnd">
    <xsl:text>{{StatementEnd:</xsl:text>
    <xsl:value-of select="local-name()" />
    <xsl:text>}}</xsl:text>
  </xsl:template>

  <!-- Перенос строки -->
  <xsl:template name="_LineBreak">
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- End of Statement -->
  <xsl:template name="_EndOfStatement">
    <xsl:text>;&#10;</xsl:text>
  </xsl:template>

  <!-- start of code block -->
  <xsl:template name="_DoBegin">
    <xsl:text>DO</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>$$</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>BEGIN</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:call-template name="_IndentInc" />
  </xsl:template>

    <!-- end of code block -->
  <xsl:template name="_DoEnd">
    <xsl:call-template name="_LineBreak" />
    <xsl:call-template name="_IndentDec" />
    <xsl:text>END;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>$$</xsl:text>
    <xsl:call-template name="_LineBreak" />
  </xsl:template>



  <!-- Object Identifier dbo_ObjectName -->
  <xsl:template match="SchemaObjectName">
    <xsl:if test="SchemaIdentifier">
      <xsl:value-of select="SchemaIdentifier/@Value" />
      <xsl:text>_</xsl:text>
    </xsl:if>
    <xsl:if
      test="BaseIdentifier">
      <xsl:value-of select="BaseIdentifier/@Value" />
    </xsl:if>
  </xsl:template>  
  <!-- Expression -->
  <xsl:template match="Expression|FirstExpression|SecondExpression|SearchCondition|ColumnReferenceExpression">
    <xsl:choose>
      <xsl:when test="@ComparisonType='GreaterThan'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> &gt; </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@ComparisonType='Equals'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> = </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@ColumnType='Regular'">
        <xsl:apply-templates select="MultiPartIdentifier" />
      </xsl:when>
      <xsl:when test="FunctionName">
        <xsl:choose>
          <xsl:when test="FunctionName/@Value = 'isnull'">
            <xsl:text>coalesce</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="FunctionName/@Value" />
          </xsl:otherwise>  
        </xsl:choose>
        <xsl:text>(</xsl:text>
        <xsl:for-each select="Parameters/ColumnReferenceExpression">
          <xsl:if test="position()>1">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="not(@Value)">
        <xsl:text>(</xsl:text>
          <xsl:apply-templates select="Expression" />
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>
      <xsl:value-of select="@Value" />
    </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- MultiPartIdentifier -->
  <xsl:template match="MultiPartIdentifier">
    <xsl:apply-templates select="Identifiers" />
  </xsl:template>

  <!-- Identifiers -->
  <xsl:template match="Identifiers">
    <xsl:for-each select="Identifier">
      <xsl:if test="position()>1">
        <xsl:text>_</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="." />
    </xsl:for-each>
  </xsl:template>


  <!-- Identifier -->
  <xsl:template match="Identifier">
    <xsl:value-of select="@Value"></xsl:value-of>
  </xsl:template>


</xsl:stylesheet>