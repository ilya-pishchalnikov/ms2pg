<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="settings.xslt" />
  <xsl:import href="common.xslt" />
  <xsl:import href="createtable.xslt" />
  
  <xsl:output omit-xml-declaration="yes" indent="yes"/>

  <!-- =================================== ТОЧКА ВХОДА =================================== -->
  <xsl:template match="/">
    <xsl:for-each select="TSqlScript/Batches/TSqlBatch/.">
      <xsl:call-template name="_StatementsSequence"/>
      <xsl:call-template name="_LineBreak"/>
      <xsl:text>/*GO*/</xsl:text>
      <xsl:call-template name="_LineBreak"/>
    </xsl:for-each>
  </xsl:template>

  <!-- Последовательность стейтментов -->
  <xsl:template name="_StatementsSequence">
    <xsl:for-each select="Statements/*">
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
        <xsl:otherwise>
          <xsl:call-template name ="_UnknownToken" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="_EndOfStatement" />
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

    <!-- Create table statement -->
  <xsl:template match="CreateTableStatement">
    <xsl:text>CREATE TABLE </xsl:text>
    <xsl:if test = "$create_table_if_not_exists">IF NOT EXISTS </xsl:if>
    <xsl:apply-templates select="SchemaObjectName"/>
    <xsl:apply-templates select="Definition" />
  </xsl:template> 


</xsl:stylesheet>