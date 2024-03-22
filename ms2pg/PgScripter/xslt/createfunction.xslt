<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ms2pg="urn:ms2pg"  >

  <!-- Create procedure statement -->
  <xsl:template match="CreateFunctionStatement|CreateOrAlterFunctionStatement">
    <xsl:text>CREATE OR REPLACE FUNCTION </xsl:text>
    <xsl:apply-templates select="Name/Identifiers" />

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
      <xsl:when test="ReturnType/DataType">
        <xsl:apply-templates select="ReturnType/DataType"/>
      </xsl:when>
      <xsl:when test="ReturnType/DeclareTableVariableBody">
        <xsl:text>SETOF out_result_table</xsl:text>
        <xsl:apply-templates select="DeclareTableVariableBody" />
      </xsl:when>
    </xsl:choose>      
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>LANGUAGE PLpgSQL</xsl:text>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>AS $$</xsl:text>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:if test="//DeclareVariableElement">
      <xsl:call-template name="_LineBreak" />
        <xsl:call-template name="_IndentInc" />
        <xsl:text>DECLARE </xsl:text>
        <xsl:call-template name="_LineBreak" />
        <xsl:for-each select="//DeclareVariableElement">
        <xsl:if test="position()>1">
          <xsl:text>;</xsl:text>
          <xsl:call-template name="_LineBreak" />
        </xsl:if>
        <xsl:apply-templates select="VariableName"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="DataType"/>
        <xsl:if test="Value">
          <xsl:text> := </xsl:text>
          <xsl:apply-templates select="Value"/>
        </xsl:if>
      </xsl:for-each>
      <xsl:text>;</xsl:text>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
    </xsl:if>
    <xsl:choose>
      <xsl:when test="ReturnType/DeclareTableVariableBody and StatementList/Statements/BeginEndBlockStatement">
        <xsl:text>BEGIN</xsl:text>
          <xsl:call-template name="_IndentInc"></xsl:call-template>
          <xsl:call-template name="_LineBreak"></xsl:call-template> 
      </xsl:when>
      <xsl:otherwise>
          <xsl:apply-templates select="StatementList" /> 
      </xsl:otherwise>
    </xsl:choose>
    <xsl:call-template name="_IndentDec"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>$$</xsl:text>
  </xsl:template>



</xsl:stylesheet>