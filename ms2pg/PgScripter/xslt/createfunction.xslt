<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ms2pg="urn:ms2pg"  >

  <!-- Create procedure statement -->
  <xsl:template match="CreateFunctionStatement|CreateOrAlterFunctionStatement">
    <xsl:text>CREATE OR REPLACE FUNCTION </xsl:text>
    <xsl:apply-templates select="Name/SchemaObjectName/Identifiers" />

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
    <xsl:text>RETURNS </xsl:text>
    <xsl:choose>
      <xsl:when test="ReturnType/ScalarFunctionReturnType/DataType">
        <xsl:apply-templates select="ReturnType/ScalarFunctionReturnType/DataType"/>
      </xsl:when>
      <xsl:when test="ReturnType/TableValuedFunctionReturnType">
        <xsl:text>TABLE </xsl:text>
        <xsl:apply-templates select="ReturnType/TableValuedFunctionReturnType/DeclareTableVariableBody/Definition/TableDefinition" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>!UNKNOWN FUNCTION RETURN TYPE!</xsl:text>
      </xsl:otherwise>
    </xsl:choose>      
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>LANGUAGE PLpgSQL</xsl:text>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>AS $$</xsl:text>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:if test="//DeclareVariableElement|//DeclareCursorStatement">
      <xsl:call-template name="_LineBreak" />
      <xsl:call-template name="_IndentInc" />
      <xsl:text>DECLARE </xsl:text>
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="//DeclareVariableElement">
        <xsl:apply-templates select="VariableName"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="DataType"/>
        <xsl:if test="Value">
          <xsl:text> := </xsl:text>
          <xsl:apply-templates select="Value"/>
        </xsl:if>
        <xsl:text>;</xsl:text>
        <xsl:call-template name="_LineBreak" />
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

    <xsl:apply-templates select="StatementList" /> 
    <xsl:call-template name="_IndentDec"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>$$</xsl:text>
  </xsl:template>




</xsl:stylesheet>