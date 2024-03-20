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
  <xsl:template match="Expression|FirstExpression|SecondExpression|SearchCondition|ColumnReferenceExpression|BinaryExpression|StringLiteral|IntegerLiteral|NewValue|WhenExpression|ThenExpression|ElseExpression|Parameter|UnaryExpression">
  <xsl:choose>
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
      <xsl:when test="FunctionName">
        <xsl:choose>
          <xsl:when test="ms2pg:ToLower(FunctionName/@Value) = 'isnull'">
            <xsl:text>coalesce</xsl:text>
          </xsl:when>
          <xsl:when test="ms2pg:ToLower(FunctionName/@Value) = 'getdate'">
            <xsl:text>now</xsl:text>
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
      <xsl:when test="@Style">
        <xsl:text>CONVERT(</xsl:text>
        <xsl:apply-templates select="DataType"/>
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="Parameter"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="@NotDefined">
        <xsl:apply-templates select="Expression"/>
        <xsl:if test="@NotDefined = 'False'">
          <xsl:text> NOT </xsl:text>          
        </xsl:if>
        <xsl:text> IN </xsl:text>
        <xsl:apply-templates select="Subquery"/>        
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
        <xsl:text>CASE</xsl:text>
        <xsl:call-template name="_IndentInc" />
        <xsl:for-each select="WhenClauses/SearchedWhenClause">
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
  

  <!-- ConvertCall -->
<!--   <xsl:template match="ConvertCall">
    <xsl:text>/*CONVERT*/</xsl:text>
    <xsl:choose>
      <xsl:when test="Style/@Value">
        <xsl:text>convert('</xsl:text>
        <xsl:value-of select="DataType/@SqlDataTypeOption" />
        <xsl:text>', </xsl:text>
        <xsl:value-of select="DataType/Parameters/IntegerLiteral[1]/@Value" />
        <xsl:text>', </xsl:text>
        <xsl:choose>
          <xsl:when test="count(DataType/Parameters) > 1">
            <xsl:value-of select="DataType/Parameters/IntegerLiteral[2]/@Value" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>-1</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>', CAST(</xsl:text>
        <xsl:value-of select="Paramenter"></xsl:value-of>         
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:otherwise>        
        <xsl:text>CAST (</xsl:text>
          <xsl:apply-templates select="Parameter/MultiPartIdentifier/Identifiers" />
          <xsl:text> AS </xsl:text>
          <xsl:apply-templates select="DataType" />
        <xsl:text>)</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="DataType" />
  </xsl:template> -->

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