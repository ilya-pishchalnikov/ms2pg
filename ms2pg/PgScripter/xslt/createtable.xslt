﻿<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
    xmlns:ms2pg="urn:ms2pg"  
>
  <xsl:import href="common.xslt"/>
  <xsl:import href="settings.xslt"/>

   <!-- Create table statement -->
  <xsl:template match="CreateTableStatement">  
    <xsl:text>CREATE </xsl:text>
    <xsl:if test="ms2pg:StartsWith(SchemaObjectName/BaseIdentifier/Identifier/@Value, '#')">
      <xsl:text>TEMP </xsl:text>
    </xsl:if>
    <xsl:text>TABLE </xsl:text>
    <xsl:if test = "$create_table_if_not_exists">IF NOT EXISTS </xsl:if>
    <xsl:apply-templates select="SchemaObjectName"/>
    <xsl:apply-templates select="Definition/TableDefinition" />
  </xsl:template>   

  <!-- TODO: inline index creation while table creating -->
  
  <!-- Table columns definition -->
  <xsl:template match="TableDefinition">
    <xsl:text>(</xsl:text>
    <xsl:call-template name = "_IndentInc" />
    <xsl:call-template name = "_IndentInc" />
    <xsl:call-template name ="_LineBreak" />
    <xsl:for-each select="ColumnDefinitions/ColumnDefinition">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="."/>
      <xsl:call-template name ="_LineBreak" />
    </xsl:for-each>
    <xsl:if test="TableConstraints/node()">
      <xsl:text>,</xsl:text>
      <xsl:apply-templates select="TableConstraints"/>
    </xsl:if>
    <xsl:call-template name = "_IndentDec" />
    <xsl:text>)</xsl:text>
    <xsl:call-template name = "_IndentDec" />
  </xsl:template>

  <!-- Table column definition -->
  <xsl:template match="ColumnDefinition">
    <xsl:value-of select="ms2pg:QuoteName(ColumnIdentifier/Identifier/@Value)" />
    <xsl:text> </xsl:text>
    <xsl:choose>
      <xsl:when test="ComputedColumnExpression">
        <xsl:variable name="table_name">
          <xsl:apply-templates select="ancestor::*/SchemaObjectName/Identifiers"/>
        </xsl:variable>
        <xsl:variable name="column_name" select="ColumnIdentifier/Identifier/@Value"/>
        <xsl:variable name="column_datatype" select="ms2pg:GetComputedColumnType($table_name, $column_name)"/>
        <xsl:value-of select="$column_datatype"/>
        <xsl:text> GENERATED ALWAYS AS (CAST (</xsl:text>
        <xsl:apply-templates select="ComputedColumnExpression/*"/>
        <xsl:text> AS </xsl:text>
        <xsl:value-of select="$column_datatype"/>
        <xsl:text>)) STORED</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="DataType"/>
        <xsl:text> </xsl:text>
        <xsl:if test="not (ancestor::TableValuedFunctionReturnType)">
          <xsl:apply-templates select="Constraints"/>          
        </xsl:if>  
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- Indexed column -->
  <xsl:template match="SqlIndexedColumn">
    <xsl:apply-templates select="SqlIdentifier"/>
  </xsl:template>

    <!-- Nullable constraint definition -->
    <xsl:template match="NullableConstraintDefinition">
      <xsl:if test="@Nullable='True'">
        <xsl:text>NULL</xsl:text>
      </xsl:if>
      <xsl:if test="@Nullable='False'">
        <xsl:text>NOT NULL</xsl:text>
      </xsl:if>
    </xsl:template>

  <!-- Column constraints definitions -->
  <xsl:template match="Constraints">
    <xsl:for-each select="*">
        <xsl:choose>
        <xsl:when test="local-name() = 'NullableConstraintDefinition'">
          <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:when test="local-name() = 'UniqueConstraintDefinition'">
          <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>/*Not recognized constraint type:  "</xsl:text>
          <xsl:value-of select="local-name()"/>
          <xsl:text>*/</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>


</xsl:stylesheet>
