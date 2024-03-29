<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Create procedure statement -->
  <xsl:template match="CreateProcedureStatement|CreateOrAlterProcedureStatement">
    <xsl:text>CREATE OR REPLACE PROCEDURE </xsl:text>
    <xsl:apply-templates select="ProcedureReference/Name/SchemaObjectName" />

    <xsl:text>(</xsl:text>
    <xsl:call-template name="_IndentInc"></xsl:call-template>
    <xsl:call-template name="_IndentInc"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:for-each select="Parameters/ProcedureParameter">
          <xsl:if test="position()>1">
            <xsl:text>,</xsl:text>
            <xsl:call-template name="_LineBreak"></xsl:call-template>
          </xsl:if>
          <xsl:if test="@Modifier='Output'">
            <xsl:text> INOUT </xsl:text>
          </xsl:if>
          <xsl:apply-templates select="VariableName" />
          <xsl:text> </xsl:text>
          <xsl:apply-templates select="DataType" />
    </xsl:for-each>
    <xsl:call-template name="_IndentDec"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>)</xsl:text>
    <xsl:call-template name="_IndentDec"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>LANGUAGE PLpgSQL</xsl:text>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>AS $$</xsl:text>  
    <xsl:if test="//DeclareVariableElement|//DeclareCursorStatement">
      <xsl:call-template name="_LineBreak" />
      <xsl:call-template name="_IndentInc" />
      <xsl:text>DECLARE </xsl:text>
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="//DeclareVariableElement">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:for-each select="//DeclareCursorStatement">
        <xsl:apply-templates select="Name/Identifier"/>
        <xsl:text> CURSOR FOR (</xsl:text>
        <xsl:call-template name="_IndentInc" />
        <xsl:call-template name="_IndentInc" />
        <xsl:call-template name="_LineBreak" />
        <xsl:apply-templates select="CursorDefinition/Select/SelectStatement"/>
        <xsl:call-template name="_IndentDec" />
        <xsl:text>)</xsl:text>
        <xsl:call-template name="_IndentDec" />
        <xsl:text>;</xsl:text>
        <xsl:call-template name="_LineBreak" />
      </xsl:for-each>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
    </xsl:if>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>BEGIN</xsl:text>
    <xsl:call-template name="_IndentInc"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>

    <xsl:apply-templates select="StatementList/Statements" />

    <xsl:call-template name="_IndentDec"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>END</xsl:text>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>$$</xsl:text>
  </xsl:template>


</xsl:stylesheet>