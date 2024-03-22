<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
  xmlns:ms2pg="urn:ms2pg"  
>
  <!-- Object Identifier dbo_ObjectName -->
  <xsl:template match="SchemaObjectName">
    <xsl:if test="SchemaIdentifier">
      <xsl:value-of select="ms2pg:QuoteName(SchemaIdentifier/@Value)" />
      <xsl:text>.</xsl:text>
    </xsl:if>
    <xsl:if test="BaseIdentifier">
      <xsl:value-of select="ms2pg:QuoteName(BaseIdentifier/@Value)" />
    </xsl:if>
  </xsl:template>  

  <!-- Expression -->
  <xsl:template match="Expression|FirstExpression|SecondExpression|SearchCondition|ColumnReferenceExpression|BinaryExpression|StringLiteral|IntegerLiteral|NewValue|WhenExpression|ThenExpression|ElseExpression|Parameter|UnaryExpression|FunctionCall|NumericLiteral|ConvertCall|InputExpression|ThirdExpression">
  <xsl:if test="@FirstTokenType='Not' and *[1]/@FirstTokenType!='Not'">
    <xsl:text> NOT </xsl:text>
  </xsl:if>  
  <xsl:choose>
      <xsl:when test="@Style and DataType[@SqlDataTypeOption='DateTime']
                             and Parameter/FunctionName[ms2pg:ToLower(@Value) = 'floor']
                             and Parameter/Parameters/ConvertCall[DataType/@SqlDataTypeOption='Float']">
        <xsl:text>CAST (</xsl:text>
        <xsl:apply-templates select="Parameter/Parameters/ConvertCall[DataType/@SqlDataTypeOption='Float']/Parameter"/>
        <xsl:text> AS DATE)</xsl:text>
      </xsl:when>
      <xsl:when test="@ColumnType='Regular'">
        <xsl:apply-templates select="MultiPartIdentifier" />
      </xsl:when>
      <xsl:when test="@ComparisonType='GreaterThan'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> &gt; </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@ComparisonType='LessThan'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> &lt; </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@ComparisonType='GreaterThanOrEqualTo'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> &gt;= </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@ComparisonType='LessThanOrEqualTo'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> &lt;= </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@ComparisonType='Equals'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> = </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@ComparisonType='NotEqualToExclamation' or @ComparisonType='NotEqualToBrackets'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> &lt;&gt; </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Add'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:choose>
          <xsl:when test="   descendant::node()[@BinaryExpressionType='Add']/FirstExpression[@LiteralType='String']
                          or descendant::node()[@BinaryExpressionType='Add']/SecondExpression[@LiteralType='String'] 
                          or ancestor-or-self::node()[@BinaryExpressionType='Add']/FirstExpression[@LiteralType='String'] 
                          or ancestor-or-self::node()[@BinaryExpressionType='Add']/SecondExpression[@LiteralType='String']">
            <xsl:text> || </xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text> + </xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Multiply'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> * </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Subtract'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> - </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Divide'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> / </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Modulo'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> % </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@IsNot='False'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:apply-templates select="Expression" />
        <xsl:text> IS NULL </xsl:text>
      </xsl:when>
      <xsl:when test="@IsNot='True'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:apply-templates select="Expression" />
        <xsl:text> IS NOT NULL </xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='And'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> AND </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@BinaryExpressionType='Or'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> OR </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
      </xsl:when>
      <xsl:when test="@TernaryExpressionType='Between'">
        <xsl:apply-templates select="FirstExpression" />
        <xsl:text> BETWEEN </xsl:text>
        <xsl:apply-templates select="SecondExpression" />
        <xsl:text> AND </xsl:text>
        <xsl:apply-templates select="ThirdExpression" />
      </xsl:when>
      <xsl:when test="@LiteralType='String'">
        <xsl:text>'</xsl:text>
        <xsl:value-of select="@Value"></xsl:value-of>
        <xsl:text>'</xsl:text>
      </xsl:when>
      <xsl:when test="@LiteralType='Integer'">
        <xsl:value-of select="@Value"></xsl:value-of>
      </xsl:when>
      <xsl:when test="starts-with(@Name, '@')">
        <xsl:text>var</xsl:text>
        <xsl:value-of select="translate(@Name, '@', '_')"></xsl:value-of>
      </xsl:when>
      <xsl:when test="QueryExpression">
        <xsl:text>(</xsl:text>
        <xsl:call-template name="_IndentInc" />
        <xsl:call-template name="_IndentInc" />
        <xsl:call-template name="_LineBreak" />
        <xsl:apply-templates select="QueryExpression" />
        <xsl:call-template name="_IndentDec" />
        <xsl:call-template name="_LineBreak" />
        <xsl:text>)</xsl:text>
        <xsl:call-template name="_IndentDec" />
      </xsl:when>
      <xsl:when test="FunctionName[ms2pg:ToLower(@Value) != 'month' and ms2pg:ToLower(@Value) != 'day' and ms2pg:ToLower(@Value) != 'datepart']">
        <xsl:choose>
          <xsl:when test="ms2pg:ToLower(FunctionName/@Value) = 'isnull'">
            <xsl:text>coalesce</xsl:text>
          </xsl:when>
          <xsl:when test="ms2pg:ToLower(FunctionName/@Value) = 'getdate'">
            <xsl:text>now</xsl:text>
          </xsl:when>
          <xsl:when test="ms2pg:ToLower(FunctionName/@Value) = 'newid'">
            <xsl:text>uuid_generate_v4</xsl:text>
          </xsl:when>
          <xsl:when test="ms2pg:ToLower(FunctionName/@Value) = 'db_name'">
            <xsl:text>current_database</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="ms2pg:QuoteName(FunctionName/@Value)" />
          </xsl:otherwise>  
        </xsl:choose>
        <xsl:text>(</xsl:text>
        <xsl:for-each select="Parameters/*">
          <xsl:if test="position()>1">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="FunctionName[ms2pg:ToLower(@Value) = 'month' or ms2pg:ToLower(@Value) = 'day']">
        <xsl:text>EXTRACT(</xsl:text>
        <xsl:value-of select="ms2pg:QuoteName(FunctionName/@Value)"/>
        <xsl:text> FROM </xsl:text>
        <xsl:for-each select="Parameters/*">
          <xsl:if test="position()>1">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="FunctionName[ms2pg:ToLower(@Value) = 'datepart']">
        <xsl:text>EXTRACT(</xsl:text>
        <xsl:apply-templates select="Parameters/ColumnReferenceExpression[1]"/>
        <xsl:text> FROM </xsl:text>
        <xsl:apply-templates select="Parameters/ColumnReferenceExpression[2]"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="@Style or local-name() = 'ConvertCall' or (@FirstTokenType='Convert' and ./DataType)">
        <xsl:text>CAST(</xsl:text>
        <xsl:apply-templates select="Parameter"/>
        <xsl:text> AS </xsl:text>
        <xsl:apply-templates select="DataType"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="@NotDefined and not (@OdbcEscape)">
        <xsl:apply-templates select="Expression"/>
        <xsl:if test="@NotDefined = 'True'">
          <xsl:text> NOT </xsl:text>          
        </xsl:if>
        <xsl:text> IN </xsl:text>
        <xsl:choose>
          <xsl:when test="Subquery/*[1]">
            <xsl:apply-templates select="Subquery"/> 
          </xsl:when>
          <xsl:when test="Values/*[1]">
            <xsl:apply-templates select="Values"/>  
          </xsl:when>
        </xsl:choose>         
      </xsl:when>

      
      <xsl:when test="@NotDefined and @OdbcEscape">
        <xsl:apply-templates select="Expression"/>
        <xsl:if test="@NotDefined = 'True'">
          <xsl:text> NOT </xsl:text>          
        </xsl:if>
        <xsl:apply-templates select="FirstExpression"/>
        <xsl:text> LIKE </xsl:text>
        <xsl:apply-templates select="SecondExpression"/>
        <xsl:if test="OdbcEscape='True'">
          <xsl:text>ESCAPE '</xsl:text>
          <xsl:value-of select="@EscapeExpression"/>
          <xsl:text>'</xsl:text>
        </xsl:if>        
      </xsl:when>

      <xsl:when test="@UnaryExpressionType">
        <xsl:choose>
          <xsl:when test="@UnaryExpressionType='Negative'">
            <xsl:text>-</xsl:text>
          </xsl:when>
          <xsl:when test="@UnaryExpressionType='Positive'">
            <xsl:text>+</xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:apply-templates select="Expression"/>
      </xsl:when>
      <xsl:when test="./WhenClauses">
        <xsl:text>CASE </xsl:text>
        <xsl:apply-templates select="InputExpression"/>
        <xsl:call-template name="_IndentInc" />
        <xsl:for-each select="WhenClauses/SearchedWhenClause | WhenClauses/SimpleWhenClause">
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
      </xsl:when>      
      <xsl:when test="ms2pg:ToLower(@FirstTokenText)='cast'">        
        <xsl:text>CAST(</xsl:text>
        <xsl:apply-templates select="Parameter"/>
        <xsl:text> AS </xsl:text>
        <xsl:apply-templates select="DataType"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="not(@Value)">
        <xsl:text>(</xsl:text>
          <xsl:apply-templates select="Expression" />
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>
      <xsl:value-of select="@Value" />
    </xsl:otherwise>
    </xsl:choose>
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
    <xsl:text>var</xsl:text>
    <xsl:value-of select="translate(@Value,'@', '_')" />
  </xsl:template> 

  <!-- Variable name -->
  <xsl:template match="Variable">
    <xsl:text>var</xsl:text>
    <xsl:value-of select="translate(@Name,'@', '_')" />
  </xsl:template>


</xsl:stylesheet>