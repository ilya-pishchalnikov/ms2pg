<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 <!-- Statements choose -->
  <xsl:template match="Statements">
    <xsl:for-each select="*">
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
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'AlterTableAddTableElementStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'CreateIndexStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'CreateViewStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'CreateProcedureStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_LineBreak" />
        </xsl:when>
        <xsl:when test="local-name() = 'BeginTransactionStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'RollbackTransactionStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'TryCatchStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'SelectStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'UpdateStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name ="_UnknownToken" />
          <xsl:call-template name="_LineBreak" />
        </xsl:otherwise>
      </xsl:choose>
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

  <!-- Begin transaction statement -->
  <xsl:template match="BeginTransactionStatement">
    <xsl:text>START TRANSACTION</xsl:text>
  </xsl:template>
  <!-- Begin transaction statement -->
  <xsl:template match="RollbackTransactionStatement">
    <xsl:text>ROLLBACK</xsl:text>
  </xsl:template>

    <!-- Try-catch statement -->
    <xsl:template match="TryCatchStatement">
      <xsl:text>BEGIN</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:apply-templates select="TryStatements/Statements" />
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>EXCEPTION WHEN OTHERS</xsl:text>
      <xsl:call-template name="_LineBreak" />
      <xsl:text>THEN</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:apply-templates select="CatchStatements/Statements" />
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>END</xsl:text>
    </xsl:template>


  <!-- Update statement -->
  <xsl:template match="UpdateStatement">
    <xsl:apply-templates select="UpdateSpecification" />
  </xsl:template>

    <!-- Update statement specification -->
    <xsl:template match="UpdateSpecification">
      <xsl:text>UPDATE </xsl:text>
      <xsl:apply-templates select="Target/SchemaObject/Identifiers" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>SET </xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="SetClauses/AssignmentSetClause">
        <xsl:apply-templates select="Column/MultiPartIdentifier/Identifiers" />
        <xsl:text> = </xsl:text>
        <xsl:apply-templates select="NewValue" />
      </xsl:for-each>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:apply-templates select="FromClause" />
      <xsl:apply-templates select="WhereClause" />
    </xsl:template>



</xsl:stylesheet>