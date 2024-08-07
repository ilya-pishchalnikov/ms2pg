<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ms2pg="urn:ms2pg"  >
 <!-- Statements choose -->
  <xsl:template match="Statements|Statement|ThenStatement|ElseStatement">
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
        <xsl:when test="local-name() = 'AlterTableConstraintModificationStatement'">
          <xsl:text>/*AlterTableConstraintModificationStatement skiped*/</xsl:text>
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
          <xsl:call-template name="_LineBreak" />
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
          <xsl:call-template name="_LineBreak" />
        </xsl:when>
        <xsl:when test="local-name() = 'UpdateStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
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
        <xsl:when test="local-name() = 'SetVariableStatement' and not (CursorDefinition)">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'SetVariableStatement' and CursorDefinition">
          <xsl:text>/*SKIPPED SET CURSOR STATEMENT*/</xsl:text>
          <xsl:call-template name="_LineBreak" />
        </xsl:when>
        <xsl:when test="local-name() = 'IfStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'InsertStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'DeclareCursorStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_LineBreak" />
        </xsl:when>
        <xsl:when test="local-name() = 'OpenCursorStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'FetchCursorStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'WhileStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'CloseCursorStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'DeallocateCursorStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_LineBreak" />
        </xsl:when>
        <xsl:when test="local-name() = 'ExecuteStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'PrintStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'CreateSchemaStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'DeclareTableVariableStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'DropTableStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'SetTransactionIsolationLevelStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'DeleteStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'BreakStatement'">
          <xsl:apply-templates select = "." />
          <xsl:call-template name="_EndOfStatement" />
        </xsl:when>
        <xsl:when test="local-name() = 'ContinueStatement'">
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
    <xsl:text>/*START TRANSACTION SKIPPED*/</xsl:text>
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
    <xsl:apply-templates select="TryStatements/StatementList/Statements" />
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>EXCEPTION WHEN OTHERS -- catch</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>THEN</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="CatchStatements/StatementList/Statements" />
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
    <xsl:variable name="target_name">
      <xsl:apply-templates select="Target/NamedTableReference/SchemaObject/SchemaObjectName/Identifiers" />
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="FromClause/TableReferences//NamedTableReference/Alias/Identifier/@Value = $target_name">
        <xsl:apply-templates select="FromClause/TableReferences//NamedTableReference[Alias/Identifier/@Value = $target_name]/SchemaObject/SchemaObjectName/Identifiers"/>
        <xsl:text> AS </xsl:text>
        <xsl:value-of select="$target_name"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="Target/NamedTableReference/SchemaObject/SchemaObjectName/Identifiers"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="Target/VariableTableReference/Variable/VariableReference">
      <xsl:apply-templates select="Target/VariableTableReference/Variable/VariableReference"/>
    </xsl:if>

    <xsl:call-template name="_LineBreak" />
    <xsl:text>SET </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="SetClauses/AssignmentSetClause">     
      <xsl:if test="position()>1">
        <xsl:text>, </xsl:text>
        <xsl:call-template name="_LineBreak" />
      </xsl:if>
      <xsl:apply-templates select="Column/ColumnReferenceExpression/MultiPartIdentifier/Identifiers" />
      <xsl:text> = </xsl:text>
      <xsl:apply-templates select="NewValue/*" />
    </xsl:for-each>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="FromClause" />
    <xsl:apply-templates select="WhereClause" />
  </xsl:template>



  <!-- Raiserror statement -->
  <xsl:template match="RaiseErrorStatement">
    <xsl:text>RAISE </xsl:text>
    <xsl:choose>
      <xsl:when test="string-length(SecondParameter/IntegerLiteral/@Value)>1 and SecondParameter/IntegerLiteral/@Value!='10'">
        <xsl:text>EXCEPTION </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>NOTICE</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>'</xsl:text>
    <xsl:value-of select="FirstParameter/StringLiteral/@Value"></xsl:value-of>
    <xsl:text>'</xsl:text>
  </xsl:template>

  
  <xsl:template match="BeginEndBlockStatement">
    <xsl:text>BEGIN</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:if test="ancestor::CreateFunctionStatement/ReturnType/TableValuedFunctionReturnType and not(ancestor::BeginEndBlockStatement)">
      <xsl:apply-templates select="ancestor::CreateFunctionStatement/ReturnType/TableValuedFunctionReturnType/DeclareTableVariableBody"/>
      <xsl:call-template name="_EndOfStatement" />
    </xsl:if>
    <xsl:apply-templates select="StatementList"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />  
    <xsl:text>END</xsl:text>
  </xsl:template>

  <xsl:template match="StatementList">
    <xsl:apply-templates select="Statements"/>
  </xsl:template>

  <xsl:template match="DeclareVariableStatement">
    <xsl:text>/* Variable declaration moved to begin of execution block */</xsl:text>
  </xsl:template>

  <xsl:template match="DeclareCursorStatement">
    <xsl:text>/* Cursor declaration moved to begin of execution bloc */</xsl:text>
  </xsl:template>
  
  <xsl:template match="ReturnStatement">
    <xsl:text>RETURN </xsl:text>
    <xsl:choose>
      <xsl:when test="ancestor::CreateFunctionStatement/ReturnType/TableValuedFunctionReturnType">
        <xsl:text>QUERY </xsl:text>   
        <xsl:call-template name="_LineBreak" />
        <xsl:text>SELECT * </xsl:text>
        <xsl:call-template name="_LineBreak" />
        <xsl:text>FROM </xsl:text>
        <xsl:apply-templates select="Variable"/>
        <xsl:value-of select="CreateFunctionStatement/ReturnType/TableValuedFunctionReturnType/DeclareTableVariableBody"/>
        <xsl:apply-templates select="ancestor::CreateFunctionStatement/ReturnType/TableValuedFunctionReturnType/DeclareTableVariableBody/VariableName"/>        
      </xsl:when>
      <xsl:when test="ancestor::CreateProcedureStatement">
        <xsl:text></xsl:text>
      </xsl:when>
      <xsl:when test="Expression">
        <xsl:apply-templates select="Expression"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>!UNKNOWN RETURN TYPE!</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="SetVariableStatement[not (CursorDefinition)]">
    <xsl:apply-templates select="Variable"/>
    <xsl:text> := </xsl:text>
    <xsl:apply-templates select="Expression"/>
  </xsl:template>
  <xsl:template match="IfStatement">
    <xsl:text>IF </xsl:text>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="Predicate"/>   
    <xsl:text>)</xsl:text> 
    <xsl:call-template name="_LineBreak" />
    <xsl:text> THEN </xsl:text>
    <xsl:call-template name="_IndentInc" /> 
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="ThenStatement"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:if test="ElseStatement">
      <xsl:call-template name="_LineBreak" />
      <xsl:text>ELSE</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" /> 
      <xsl:apply-templates select="ElseStatement"/>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />  
    </xsl:if>
    <xsl:text>END IF</xsl:text>
  </xsl:template>

  <xsl:template match="DeclareTableVariableBody">
    <xsl:text>CREATE TEMP TABLE IF NOT EXISTS </xsl:text>
    <xsl:apply-templates select="VariableName"/>
    <xsl:apply-templates select="Definition/TableDefinition"/>
  </xsl:template>

  <xsl:template match="InsertStatement">
    <xsl:if test="WithCtesAndXmlNamespaces">
      <xsl:apply-templates select="WithCtesAndXmlNamespaces"/>
    </xsl:if>
    
    <xsl:text>INSERT INTO </xsl:text>
    <xsl:apply-templates select="InsertSpecification/Target/VariableTableReference|InsertSpecification/Target/NamedTableReference"/>
    <xsl:if test="InsertSpecification/Columns/ColumnReferenceExpression">
      <xsl:text>(</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="InsertSpecification/Columns/ColumnReferenceExpression">    
        <xsl:if test="position()>1">
          <xsl:text>, </xsl:text>
          <xsl:call-template name="_LineBreak" />
        </xsl:if>
        <xsl:apply-templates select="MultiPartIdentifier"/>
      </xsl:for-each>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:call-template name="_IndentDec" />
      <xsl:text>)</xsl:text>      
    </xsl:if>
    <xsl:call-template name="_LineBreak" />
    <xsl:choose>
      <xsl:when test="InsertSpecification/InsertSource/SelectInsertSource/Select">
        <xsl:apply-templates select="InsertSpecification/InsertSource/SelectInsertSource/Select"/>
      </xsl:when>
      <xsl:when test="InsertSpecification/InsertSource/ValuesInsertSource">
        <xsl:apply-templates select="InsertSpecification/InsertSource/ValuesInsertSource"/>
      </xsl:when>
      <xsl:when test="InsertSpecification/InsertSource/ExecuteInsertSource/Execute">
        <xsl:apply-templates select="InsertSpecification/InsertSource/ExecuteInsertSource/Execute/ExecuteSpecification"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>!UNKNOWN!</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="OpenCursorStatement">
    <xsl:text>OPEN </xsl:text>
    <xsl:apply-templates select="Cursor/CursorId/Name/IdentifierOrValueExpression/Identifier|Cursor/CursorId/Name/IdentifierOrValueExpression/ValueExpression/VariableReference"/>    
  </xsl:template>

  <xsl:template match="FetchCursorStatement">
    <xsl:text>FETCH </xsl:text>
    <xsl:choose>
      <xsl:when test="FetchType/@Orientation='Next'">
        <xsl:text>NEXT </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="FetchType/@Orientation"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>FROM </xsl:text>
    <xsl:apply-templates select="Cursor/CursorId/Name/IdentifierOrValueExpression/Identifier|Cursor/CursorId/Name/IdentifierOrValueExpression/ValueExpression/VariableReference"/> 
    <xsl:text> INTO </xsl:text>
    <xsl:for-each select="IntoVariables/VariableReference">
      <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="WhileStatement">
    <xsl:text>WHILE </xsl:text>
    <xsl:apply-templates select="Predicate"/>
    <xsl:text> LOOP</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="Statement"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>END LOOP</xsl:text>
  </xsl:template>
  <xsl:template match="CloseCursorStatement">
    <xsl:text>CLOSE </xsl:text>
    <xsl:apply-templates select="Cursor/CursorId/Name/IdentifierOrValueExpression/Identifier|Cursor/CursorId/Name/IdentifierOrValueExpression/ValueExpression/VariableReference"/>
  </xsl:template>

  <xsl:template match="DeallocateCursorStatement">
    <xsl:text>/* SKIPPED Deallocate cursor statement */</xsl:text>
  </xsl:template>

  <xsl:template match="ExecuteStatement">
    <xsl:apply-templates select="ExecuteSpecification"/>
  </xsl:template>
  <xsl:template match="ExecuteSpecification">
    <xsl:choose>
      <xsl:when test="ExecutableEntity/ExecutableProcedureReference/ProcedureReference/ProcedureReferenceName/ProcedureReference/Name/SchemaObjectName/Identifiers">
        <xsl:variable name="procedure_name" >
          <xsl:apply-templates select="ExecutableEntity/ExecutableProcedureReference/ProcedureReference/ProcedureReferenceName/ProcedureReference/Name/SchemaObjectName/Identifiers"/>
        </xsl:variable>
        <xsl:if test="$procedure_name != 'sp_settriggerorder'">
          <xsl:choose>
            <xsl:when test="ms2pg:IsProcedureHasResultSet($procedure_name)">
              <xsl:text>SELECT * FROM </xsl:text>
            </xsl:when>
            <xsl:when test="ancestor::ExecuteInsertSource">
              <xsl:text>SELECT * FROM </xsl:text>
            </xsl:when>
            <xsl:otherwise>            
              <xsl:text>CALL </xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates select="ExecutableEntity/ExecutableProcedureReference/ProcedureReference/ProcedureReferenceName/ProcedureReference/Name/SchemaObjectName/Identifiers"/>
          <xsl:text>(</xsl:text>
          <xsl:call-template name="_IndentInc" />
          <xsl:call-template name="_IndentInc" />
          <xsl:for-each select="ExecutableEntity/ExecutableProcedureReference/Parameters/ExecuteParameter">
            <xsl:if test="position() > 1">
              <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:call-template name="_LineBreak" />
            <xsl:if test="Variable">
              <xsl:apply-templates select="Variable"/>
              <xsl:text> => </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="ParameterValue/*"/>
            <xsl:if test="@IsOutput='true'">
              <xsl:text> OUT</xsl:text>
            </xsl:if>
          </xsl:for-each>
          <xsl:apply-templates select="ExecutableEntity/ExecutableStringList/Strings/*"/>
          <xsl:call-template name="_IndentDec" />
          <xsl:call-template name="_LineBreak" />
          <xsl:text>)</xsl:text>
          <xsl:call-template name="_IndentDec" />
        </xsl:if>
      </xsl:when>
      <xsl:when test="ExecutableEntity/ExecutableStringList/Strings">
         <xsl:text>EXECUTE </xsl:text>
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="ExecutableEntity/ExecutableStringList/Strings/*"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>!UNKNOWN! execute statement</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="PrintStatement">
    <xsl:text>RAISE NOTICE '%', </xsl:text>
    <xsl:apply-templates select="Expression"/>
  </xsl:template>

  <xsl:template match="WithCtesAndXmlNamespaces">
    <xsl:text>WITH </xsl:text>
    <xsl:for-each select="CommonTableExpressions/CommonTableExpression">
      <xsl:if test="position() > 1">
        <xsl:call-template name="_LineBreak" />
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="ExpressionName/Identifier"/>
      <xsl:if test="Columns/node()">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="Columns"/>
        <xsl:text>) </xsl:text>
      </xsl:if>
      <xsl:text> AS (</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:apply-templates select="QueryExpression"/>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>      
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="CreateSchemaStatement">
    <xsl:text>CREATE SCHEMA IF NOT EXISTS </xsl:text>
    <xsl:apply-templates select="Name/Identifier"/>
  </xsl:template>

  <xsl:template match="DeclareTableVariableStatement">
    <xsl:text>CREATE TEMP TABLE tmp_var_</xsl:text>
    <xsl:value-of select="substring(Body/DeclareTableVariableBody/VariableName/Identifier/@Value, 2, string-length (Body/DeclareTableVariableBody/VariableName/Identifier/@Value) - 1)"/>
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="Body/DeclareTableVariableBody/Definition/TableDefinition"/>
  </xsl:template>

  <xsl:template match="DropTableStatement">
    <xsl:text>DROP TABLE </xsl:text>
    <xsl:if test="@IsIfExists = 'True'">
      <xsl:text>IF EXISTS </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="Objects/SchemaObjectName/Identifiers"/>
  </xsl:template>

  <xsl:template match="SetTransactionIsolationLevelStatement">
    <xsl:text>SET TRANSACTION ISOLATION LEVEL </xsl:text>
    <xsl:choose>
      <xsl:when test="@Level='ReadUncommitted'">
        <xsl:text>READ UNCOMMITTED</xsl:text>
      </xsl:when>
      <xsl:when test="@Level='ReadCommitted'">
        <xsl:text>READ COMMITTED</xsl:text>
      </xsl:when>
      <xsl:when test="@Level='RepeatableRead'">
        <xsl:text>REPEATABLE READ</xsl:text>
      </xsl:when>
      <xsl:when test="@Level='Serializable'">
        <xsl:text>Serializable</xsl:text>
      </xsl:when>
      <xsl:when test="@Level='Snapshot'">
        <xsl:text>Serializable</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="DeleteStatement">
    <xsl:text>DELETE FROM </xsl:text>
    <xsl:apply-templates select="DeleteSpecification/Target/NamedTableReference/SchemaObject/SchemaObjectName/Identifiers|DeleteSpecification/Target/VariableTableReference/Variable"/>
    <xsl:apply-templates select="WhereClause"/>
  </xsl:template>

  <xsl:template match="BreakStatement">
    <xsl:text>EXIT</xsl:text>
  </xsl:template>
  <xsl:template match="ContinueStatement">
    <xsl:text>CONTINUE</xsl:text>
  </xsl:template>

</xsl:stylesheet>