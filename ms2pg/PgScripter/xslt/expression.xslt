<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
                xmlns:ms2pg="urn:ms2pg"  
  >
  <!-- Object Identifier dbo_ObjectName -->
  <xsl:template match="SchemaObjectName">
    <xsl:apply-templates select="Identifiers"/>
  </xsl:template>  
  
  <xsl:template match="Expression|FirstExpression|SecondExpression|ThirdExpression|InputExpression|WhenExpression|ThenExpression|ElseExpression">
    <xsl:apply-templates select="*"/>    
  </xsl:template>

  <xsl:template match="SearchCondition">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="BooleanParenthesisExpression">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="Expression"/>
    <xsl:text>)</xsl:text>    
  </xsl:template>

  <xsl:template match="BooleanIsNullExpression">
    <xsl:apply-templates select="Expression"/>
    <xsl:text> IS </xsl:text>
    <xsl:if test="@IsNot='True'">
      <xsl:text>NOT </xsl:text>
    </xsl:if>
    <xsl:text>NULL</xsl:text>
  </xsl:template>

  <xsl:template match="BooleanComparisonExpression">
    <xsl:apply-templates select="FirstExpression"/>
    <xsl:choose>
      <xsl:when test="@ComparisonType='GreaterThan'">
        <xsl:text> &gt; </xsl:text>
      </xsl:when>
      <xsl:when test="@ComparisonType='LessThan'">
        <xsl:text> &lt; </xsl:text>
      </xsl:when>
      <xsl:when test="@ComparisonType='GreaterThanOrEqualTo'">
        <xsl:text> &gt;= </xsl:text>
      </xsl:when>
      <xsl:when test="@ComparisonType='LessThanOrEqualTo'">
        <xsl:text> &lt;= </xsl:text>
      </xsl:when>
      <xsl:when test="@ComparisonType='Equals'">
        <xsl:text> = </xsl:text>
      </xsl:when>
      <xsl:when test="@ComparisonType='NotEqualToExclamation' or @ComparisonType='NotEqualToBrackets'">
        <xsl:text> &lt;&gt; </xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates select="SecondExpression"/>
  </xsl:template>

  <xsl:template match="BooleanBinaryExpression">
    <xsl:apply-templates select="FirstExpression"/>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:call-template name="_IndentDec" />
    <xsl:choose>
      <xsl:when test="@BinaryExpressionType='And'">
        <xsl:text> AND </xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Or'">
        <xsl:text> OR </xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates select="SecondExpression"/>
  </xsl:template>


  <xsl:template match="BinaryExpression">
    <xsl:apply-templates select="FirstExpression"/>
    <xsl:choose>
      <xsl:when test="@BinaryExpressionType='Add'">
        <xsl:text> + </xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Multiply'">
        <xsl:text> * </xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Subtract'">
        <xsl:text> - </xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Divide'">
        <xsl:text> / </xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Modulo'">
        <xsl:text> % </xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates select="SecondExpression"/>
  </xsl:template>


  <xsl:template match="ParenthesisExpression">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="Expression"/>
    <xsl:text>)</xsl:text>    
  </xsl:template>

  <xsl:template match="IntegerLiteral">
    <xsl:value-of select="@Value"/>
  </xsl:template>
  
  <xsl:template match="StringLiteral">
    <xsl:text>'</xsl:text>
    <xsl:value-of select="ms2pg:DoubleQuotes(@Value)"/>
    <xsl:text>'</xsl:text>
  </xsl:template>

  <xsl:template match="ColumnReferenceExpression">
    <xsl:choose>
      <xsl:when test="@ColumnType='Wildcard'">
        <xsl:text>*</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="MultiPartIdentifier"/>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <xsl:template match="UnaryExpression">
    <xsl:choose>
      <xsl:when test="@UnaryExpressionType='Negative'">
        <xsl:text>-</xsl:text>        
      </xsl:when>
      <xsl:when test="@UnaryExpressionType='Positive'">
        <xsl:text>+</xsl:text>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>!UNKNOWN UNARY EXPRESSION TYPE!</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="Expression"/>
  </xsl:template>

  <xsl:template match="FunctionCall">
    <xsl:variable name="function_name" select="ms2pg:ToLower(FunctionName/Identifier/@Value)"/>
    <xsl:choose>
      <xsl:when test="$function_name='day' or $function_name='year' or $function_name = 'month' ">
        <xsl:text>EXTRACT (</xsl:text>
        <xsl:value-of select="$function_name"/>
        <xsl:text> FROM </xsl:text>
        <xsl:apply-templates select="Parameters"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="$function_name='datepart'">
        <xsl:text>EXTRACT (</xsl:text>
        <xsl:apply-templates select="Parameters/*[1]"/>
        <xsl:text> FROM </xsl:text>
        <xsl:apply-templates select="Parameters/*[2]"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="$function_name='dateadd'">
        <xsl:apply-templates select="Parameters/*[3]"/>
        <xsl:text> + INTERVAL '</xsl:text>
        <xsl:apply-templates select="Parameters/*[2]"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="Parameters/*[1]"/>
        <xsl:text>'</xsl:text>
      </xsl:when>
      <xsl:when test="$function_name='datediff'">
        <xsl:text>dbo.DateDiff ('</xsl:text>
        <xsl:apply-templates select="Parameters/*[1]"/>
        <xsl:text>', </xsl:text>
        <xsl:apply-templates select="Parameters/*[2]"/>
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="Parameters/*[3]"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="$function_name='charindex'">
        <xsl:text>strpos (</xsl:text>
        <xsl:apply-templates select="Parameters/*[1]"/>
        <xsl:text>, </xsl:text>
        <xsl:choose>
          <xsl:when test="count(Parameters/*) > 2">            
            <xsl:text>substr(</xsl:text>
            <xsl:apply-templates select="Parameters/*[2]"/>
            <xsl:text>, </xsl:text>
            <xsl:apply-templates select="Parameters/*[3]"/>
            <xsl:text>)</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="Parameters/*[2]"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="$function_name='round'">
        <xsl:text>ROUND(CAST(</xsl:text>
        <xsl:apply-templates select="Parameters/*[1]"/>
        <xsl:text> AS NUMERIC), </xsl:text>
        <xsl:apply-templates select="Parameters/*[2]"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
    <xsl:otherwise>      
      <xsl:choose>
        <xsl:when test="$function_name = 'getdate'">
          <xsl:text>now</xsl:text>
        </xsl:when>
        <xsl:when test="$function_name = 'isnull'">
          <xsl:text>coalesce</xsl:text>
        </xsl:when>
        <xsl:when test="$function_name = 'newid'">
          <xsl:text>public.uuid_generate_v4</xsl:text>
        </xsl:when>
        <xsl:when test="$function_name = 'db_name'">
          <xsl:text>current_database</xsl:text>
        </xsl:when>
        <xsl:when test="$function_name = 'char'">
          <xsl:text>chr</xsl:text>
        </xsl:when>
        <xsl:when test="$function_name = 'len'">
          <xsl:text>length</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$function_name"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>(</xsl:text>
      <xsl:apply-templates select="Parameters"/>
      <xsl:text>)</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="OverClause/node()">
      <xsl:text>OVER (</xsl:text>
      <xsl:if test="OverClause/OrderByClause/node()">
        <xsl:text>ORDER BY </xsl:text>
        <xsl:apply-templates select="OverClause/OrderByClause/OrderByElements"/>
      </xsl:if>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ConvertCall|CastCall">
    <xsl:choose>
      <xsl:when test="DataType/SqlDataTypeReference/@SqlDataTypeOption='DateTime'
        and ms2pg:ToLower(Parameter/FunctionCall/FunctionName/Identifier/@Value) = 'floor'
        and Parameter/FunctionCall/Parameters/ConvertCall/DataType/SqlDataTypeReference/@SqlDataTypeOption='Float'"
        >
        <xsl:text>date_trunc ('day', </xsl:text>
        <xsl:apply-templates select="Parameter/FunctionCall/Parameters/ConvertCall/Parameter"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>        
        <xsl:text>CAST(</xsl:text>
        <xsl:apply-templates select="Parameter"/>
        <xsl:text> AS </xsl:text>
        <xsl:apply-templates select="DataType"/>
        <xsl:text>)</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="OrderByElements">
    <xsl:for-each select="ExpressionWithSortOrder">
        <xsl:if test="position() > 1">
          <xsl:call-template name="_LineBreak" />
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="Expression" />
        <xsl:choose>
          <xsl:when test="@SortOrder='Ascending'">
            <xsl:text> ASC </xsl:text>
          </xsl:when>
          <xsl:when test="@SortOrder='Descending'">
            <xsl:text> DESC </xsl:text>
          </xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
  </xsl:template>

  <xsl:template match="BooleanTernaryExpression[@TernaryExpressionType='Between']">
    <xsl:apply-templates select="FirstExpression"/>
    <xsl:text> BETWEEN </xsl:text>
    <xsl:apply-templates select="SecondExpression"/>
    <xsl:text> AND </xsl:text>
    <xsl:apply-templates select="ThirdExpression"/>
  </xsl:template>
  
  <xsl:template match="NullLiteral">
    <xsl:text> NULL </xsl:text>
  </xsl:template>
  
  <xsl:template match="NumericLiteral">
    <xsl:value-of select="@Value"/>
  </xsl:template>
  
  <xsl:template match="SimpleCaseExpression|SearchedCaseExpression">
    <xsl:text>CASE </xsl:text>
    <xsl:apply-templates select="InputExpression"/>
    <xsl:call-template name="_IndentInc" />
    <xsl:for-each select="WhenClauses/SearchedWhenClause|WhenClauses/SimpleWhenClause">
      <xsl:call-template name="_LineBreak" />
      <xsl:text>WHEN </xsl:text>
      <xsl:apply-templates select="WhenExpression"/> 
      <xsl:call-template name="_LineBreak" />  
      <xsl:text>THEN </xsl:text>
      <xsl:apply-templates select="ThenExpression"/>
    </xsl:for-each>
    <xsl:if test="ElseExpression">
      <xsl:call-template name="_LineBreak" />
      <xsl:text>ELSE </xsl:text>
      <xsl:apply-templates select="ElseExpression"/>
    </xsl:if>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>END</xsl:text>
  </xsl:template>

  <xsl:template match="ScalarSubquery">
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>(</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="QueryExpression"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:text>)</xsl:text>
    <xsl:call-template name="_IndentDec" />    
  </xsl:template>
  <xsl:template match="Predicate">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="LikePredicate">
    <xsl:apply-templates select="FirstExpression"/>
    <xsl:text> LIKE </xsl:text>
    <xsl:apply-templates select="SecondExpression"/>
  </xsl:template>
  
  
  <xsl:template match="InPredicate">
    <xsl:apply-templates select="Expression"/>
    <xsl:if test="@NotDefined='True'">
      <xsl:text> NOT</xsl:text>
    </xsl:if>
    <xsl:text> IN </xsl:text>
    <xsl:if test="Values/node()">
      <xsl:for-each select="Values">      
        <xsl:if test="position()>1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </xsl:if>
    <xsl:if test="Subquery/node()">
      <xsl:apply-templates select="Subquery/ScalarSubquery"/>
    </xsl:if>    
  </xsl:template>

  <xsl:template match="ExistsPredicate">
    <xsl:text>EXISTS (</xsl:text>    
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="Subquery/ScalarSubquery/QueryExpression"/>
    
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>)</xsl:text>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>
  
  <!-- MultiPartIdentifier -->  
  <xsl:template match="MultiPartIdentifier">
    <xsl:apply-templates select="Identifiers" />
  </xsl:template>
  
  <!-- values clause -->  
  <xsl:template match="Values">
    <xsl:text>(</xsl:text>    
    <xsl:for-each select="*">
      <xsl:if test="position()>1">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="." />
    </xsl:for-each>
    <xsl:text>)</xsl:text>    
  </xsl:template>
  
  <!-- Identifiers -->
  <xsl:template match="Identifiers">
    <xsl:for-each select="Identifier">
      <xsl:if test="position()>1">
        <xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="." />
    </xsl:for-each>
  </xsl:template>
  
  
  <!-- Identifier -->
  <xsl:template match="Identifier">
    <xsl:value-of select="ms2pg:QuoteName(@Value)"></xsl:value-of>
  </xsl:template>
  
  
  <!-- Variable name -->
  <xsl:template match="VariableName">
    <xsl:if test="ancestor::DeclareTableVariableBody">
      <xsl:text>tmp_</xsl:text>
    </xsl:if>
    <xsl:text>var</xsl:text>
    <xsl:value-of select="ms2pg:QuoteName(translate(Identifier/@Value,'@', '_'))" />
  </xsl:template> 
  
  <!-- Variable name -->
  <xsl:template match="Variable">
    <xsl:apply-templates select="VariableReference"/>
  </xsl:template>

  <xsl:template match="VariableReference">
    <xsl:if test="ancestor::VariableTableReference">
      <xsl:text>tmp_</xsl:text>
    </xsl:if>
    <xsl:text>var</xsl:text>
    <xsl:value-of select="translate(@Name,'@', '_')" />
  </xsl:template>
  
  <xsl:template match="Parameters">
    <xsl:for-each select="*">
      <xsl:if test="position()>1">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="." />
    </xsl:for-each>  
  </xsl:template>

  <xsl:template match="Parameter">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="NullIfExpression">
    <xsl:text>nullif(</xsl:text>
    <xsl:apply-templates select="FirstExpression"/>
    <xsl:text>, </xsl:text>
    <xsl:apply-templates select="SecondExpression"/>
    <xsl:text>)</xsl:text>
  </xsl:template>
  
  <xsl:template match="VariableTableReference">
    <xsl:apply-templates select="Variable"/>
    <xsl:if test="@Alias != ''">
      <xsl:text> AS </xsl:text>
      <xsl:value-of select="ms2pg:QuoteName(@Alias)"/>
    </xsl:if>
    <xsl:if test="Alias">
      <xsl:text> AS </xsl:text>
      <xsl:apply-templates select="Alias/Identifier"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="GlobalVariableExpression">
    <xsl:choose>
      <xsl:when test="ms2pg:ToLower(@Name)='@@fetch_status'">
        <xsl:text>CASE WHEN FOUND THEN 0 ELSE -1 END</xsl:text>
      </xsl:when>
      <xsl:when test="ms2pg:ToLower(@Name)='@@spid'">
        <xsl:text>pg_backend_pid()</xsl:text>
      </xsl:when>
      <xsl:when test="ms2pg:ToLower(@Name)='@@servername'">
        <xsl:text>inet_server_addr()</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/*!UNKNOWN! GLOBAL VARIABLE </xsl:text>
        <xsl:value-of select="@Name"/>
        <xsl:text> */</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="Value">
    <xsl:apply-templates select="*"/>
  </xsl:template>

    <xsl:template match="CoalesceExpression">
      <xsl:text>COALESCE (</xsl:text>
      <xsl:for-each select="Expressions/*">
        <xsl:if test="position() > 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:text>)</xsl:text>
    </xsl:template>
</xsl:stylesheet>