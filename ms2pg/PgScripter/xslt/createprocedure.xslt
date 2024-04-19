<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ms2pg="urn:ms2pg"  >

  <!-- Create procedure statement -->
  <xsl:template match="CreateProcedureStatement|CreateOrAlterProcedureStatement">
    <xsl:variable name="procedure_name">
      <xsl:apply-templates select="ProcedureReference/Name/SchemaObjectName" />
    </xsl:variable>
    <xsl:variable name="is_function" select="ms2pg:IsProcedureHasResultSet($procedure_name)"/>
    <xsl:text>CREATE OR REPLACE </xsl:text>
    <xsl:choose>
      <xsl:when test="$is_function">
        <xsl:text>FUNCTION </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>PROCEDURE </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$procedure_name"/>

    <xsl:text>(</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="Parameters/ProcedureParameter">
          <xsl:if test="position()>1">
            <xsl:text>,</xsl:text>
            <xsl:call-template name="_LineBreak" />
          </xsl:if>
          <xsl:if test="@Modifier='Output'">
            <xsl:text> INOUT </xsl:text>
          </xsl:if>
          <xsl:apply-templates select="VariableName" />
          <xsl:text> </xsl:text>
          <xsl:apply-templates select="DataType" />
    </xsl:for-each>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>)</xsl:text>
    <xsl:if test="$is_function">
      <xsl:call-template name="_LineBreak" />
      <xsl:text>RETURNS TABLE (</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:value-of select="ms2pg:GetProcedureTableDefinition($procedure_name)"/>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>LANGUAGE PLpgSQL</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>AS $$</xsl:text>  
    <xsl:call-template name="_LineBreak"></xsl:call-template>
    <xsl:text>#variable_conflict use_column</xsl:text>
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
    <xsl:text>$$;</xsl:text><xsl:call-template name="_LineBreak" />
    <xsl:text>COMMIT;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>-- Temp tables create {{</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="//DeclareTableVariableStatement|//DeclareTableVariableBody|//CreateTableStatement[ms2pg:StartsWith(SchemaObjectName/BaseIdentifier/Identifier/@Value, '#')]">
      <xsl:apply-templates select="."/>
      <xsl:call-template name="_EndOfStatement" />
    </xsl:for-each>
    <xsl:text>-- }} Temp tables create</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>Do LANGUAGE plpgsql $$</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>declare </xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>    var_message varchar;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>Begin</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>    if exists (select * from public.plpgsql_check_function_tb('</xsl:text>
    <xsl:apply-templates select="ProcedureReference/Name/SchemaObjectName" />
    <xsl:text>') where level = 'error') THEN</xsl:text>
    <xsl:call-template name="_LineBreak" />    
    <xsl:text>        select CONCAT ('{{CHECK ERROR}}', 'function: [[</xsl:text>
    <xsl:apply-templates select="ProcedureReference/Name/SchemaObjectName" />
    <xsl:text>]]', E'\nline no: ' || t.lineno, E'\nMessage: ' || sqlstate || ': ' || "message",  E'\n' || detail, E'\n' || hint) </xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>        into var_message</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>        from public.plpgsql_check_function_tb('</xsl:text>
    <xsl:apply-templates select="ProcedureReference/Name/SchemaObjectName" />
    <xsl:text>' ) t</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>        where level = 'error';</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>         RAISE EXCEPTION '%', var_message;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>    end if;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>End;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>$$</xsl:text>
  </xsl:template>


</xsl:stylesheet>