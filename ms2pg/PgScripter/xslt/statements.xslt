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
          <xsl:call-template name="_EndOfStatement" />
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
        <xsl:when test="local-name() = 'CommitTransactionStatement'">
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
        <xsl:when test="local-name() = 'InsertStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_LineBreak" />
        </xsl:when>
        <xsl:when test="local-name() = 'RaiseErrorStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'CreateFunctionStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'BeginEndBlockStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'DeclareVariableStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_LineBreak" />
        </xsl:when>
        <xsl:when test="local-name() = 'ReturnStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'SetVariableStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'IfStatement'">
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

  <!-- Rollback transaction statement -->
  <xsl:template match="RollbackTransactionStatement">
    <xsl:text>ROLLBACK</xsl:text>
  </xsl:template>
  
  <!-- Commit transaction statement -->
  <xsl:template match="CommitTransactionStatement">
    <xsl:text>COMMIT</xsl:text>
  </xsl:template>

  <!-- Try-catch statement -->
  <xsl:template match="TryCatchStatement">
    <xsl:text>BEGIN -- try</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="TryStatements/Statements" />
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>EXCEPTION WHEN OTHERS -- catch</xsl:text>
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



    <!-- Insert statement -->
  <xsl:template match="InsertStatement">
    <xsl:choose>
      <xsl:when test="InsertSpecification/InsertSource/Execute">
        <xsl:text>/********************** INSERT-EXEC NOT SUPPORTED **********************/</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="_UnknownToken" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Raiserror statement -->
  <xsl:template match="RaiseErrorStatement">
    <xsl:text>RAISE </xsl:text>
    <xsl:choose>
      <xsl:when test="string-length(SecondParameter/@Value)>1 and SecondParameter/@Value!='10'">
        <xsl:text>EXCEPTION </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>NOTICE</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>'</xsl:text>
    <xsl:value-of select="FirstParameter/@Value"></xsl:value-of>
    <xsl:text>'</xsl:text>
  </xsl:template>

  
  <xsl:template match="BeginEndBlockStatement">
    <xsl:call-template name="_LineBreak" />
    <xsl:call-template name="_IndentInc" />
    <xsl:text>BEGIN</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="StatementList"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />  
    <xsl:text>END</xsl:text>      
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <xsl:template match="DeclareVariableStatement">
    <xsl:text>/* Variable declaration moved into begin of execution statement */</xsl:text>
  </xsl:template>
  
  <xsl:template match="ReturnStatement">
    <xsl:text>RETURN </xsl:text>
    <xsl:apply-templates select="Expression"/>
  </xsl:template>
  
  <xsl:template match="SetVariableStatement">
    <xsl:apply-templates select="Variable"/>
    <xsl:text> := </xsl:text>
    <xsl:apply-templates select="Expression"/>
  </xsl:template>
  <!--xsl:template match="IfStatement">
    <xsl:text>IF </xsl:text>
    <xsl:apply-templates select="Predicate"/>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>THEN</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />    
    <xsl:apply-templates select="ThenStatement"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />  
    <xsl:if test="ElseStatement">
      <xsl:text>ELSE</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" /> 
      <xsl:apply-templates select="ElseStatement"/>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />  
    </xsl:if>
    <xsl:text>END IF</xsl:text>
    <xsl:call-template name="_LineBreak" /> 
  </xsl:template-->



</xsl:stylesheet>