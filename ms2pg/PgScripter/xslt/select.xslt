<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ms2pg="urn:ms2pg"  >

  <!-- Select statement -->
  <xsl:template match="SelectStatement">
    <xsl:if test="WithCtesAndXmlNamespaces">
      <xsl:apply-templates select="WithCtesAndXmlNamespaces"/>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="not (descendant::SelectSetVariable) and local-name(ancestor::*[1])!='Select' and ancestor::CreateProcedureStatement" >
        <xsl:variable name="procedure_name">
          <xsl:apply-templates select="ancestor::CreateProcedureStatement/ProcedureReference/Name/SchemaObjectName|ancestor::CreateOrAterProcedureStatement/ProcedureReference/Name/SchemaObjectName" />
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="ms2pg:IsProcedureHasResultSet($procedure_name)">
            <xsl:text>RETURN QUERY </xsl:text>
            <xsl:call-template name="_LineBreak" />
            <xsl:text>SELECT </xsl:text>
            <xsl:call-template name="_IndentInc" />
            <xsl:call-template name="_LineBreak" />
            <xsl:value-of select="ms2pg:GetProcedureQueryFieldsDefinition($procedure_name)"/>
            <xsl:call-template name="_LineBreak" />
            <xsl:text>FROM (</xsl:text>
            <xsl:call-template name="_IndentInc" />
            <xsl:call-template name="_LineBreak" />
            <xsl:apply-templates select="QueryExpression" />
            <xsl:call-template name="_IndentDec" />
            <xsl:call-template name="_LineBreak" />
            <xsl:text>) t</xsl:text>
            <xsl:call-template name="_IndentDec" />
            <xsl:call-template name="_LineBreak" />
            <xsl:call-template name="_EndOfStatement" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>/*SELECT STATEMENT SKIPPED*/</xsl:text>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:when>
      <xsl:when test="ancestor::SelectFunctionReturnType">
        <xsl:apply-templates select="QueryExpression" />
      </xsl:when>
      <xsl:when test="ancestor::CursorDefinition">
        <xsl:apply-templates select="QueryExpression" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="QueryExpression" />
        <xsl:call-template name="_EndOfStatement" />
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template match="QueryExpression|FirstQueryExpression|SecondQueryExpression">
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <xsl:template match="BinaryQueryExpression">
    <xsl:text>(</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="FirstQueryExpression"/>
    <xsl:text>)</xsl:text>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:choose>
      <xsl:when test="@BinaryQueryExpressionType='Union'">
        <xsl:text>UNION</xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryQueryExpressionType='Except'">
        <xsl:text>EXCEPT</xsl:text>
      </xsl:when>
      <xsl:when test="@BinaryQueryExpressionType='Intersect'">
        <xsl:text>INTERSECT</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>(</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="SecondQueryExpression"/>
    <xsl:text>)</xsl:text>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!-- Query -->
  <xsl:template match="QuerySpecification">
    <xsl:choose>
      <xsl:when test="ForClause/XmlForClause">
        <xsl:apply-templates select="SelectElements" mode="ForXml" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="SelectElements" />
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="FromClause" />
    <xsl:apply-templates select="WhereClause" />
    <xsl:apply-templates select="GroupByClause" />
    <xsl:apply-templates select="HavingClause" />
    <xsl:apply-templates select="OrderByClause" />
    <xsl:apply-templates select="TopRowFilter"/>
  </xsl:template>

  <!-- Select clause -->
  <xsl:template match="SelectElements">
    <xsl:text>SELECT </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="*">
      <xsl:if test="position() > 1">
        <xsl:call-template name="_LineBreak" />
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="local-name()='SelectScalarExpression'">
          <xsl:choose>
            <xsl:when test="@FirstTokenText and ms2pg:ToLower(Expression/FunctionCall/FunctionName/Identifier/@Value)='value'">
              <xsl:text>unnest(xpath(</xsl:text>
              <xsl:apply-templates select="Expression/FunctionCall/Parameters/*[1]"/>
              <xsl:text>, </xsl:text>
              <xsl:value-of select="@FirstTokenText"/>
              <xsl:text>))</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="Expression"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="local-name()='SelectSetVariable'">
          <xsl:apply-templates select="Expression" />
        </xsl:when>
        <xsl:when test="local-name()='SelectStarExpression'">
          <xsl:if test="Qualifier/MultiPartIdentifier">
            <xsl:apply-templates select="Qualifier/MultiPartIdentifier/Identifiers"/>
            <xsl:text>.</xsl:text>
          </xsl:if>
          <xsl:text>*</xsl:text>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      <xsl:if test="ColumnName/node()">
        <xsl:text> AS </xsl:text>
        <xsl:apply-templates select="ColumnName/IdentifierOrValueExpression/Identifier" />
        <xsl:if test="ColumnName/IdentifierOrValueExpression/ValueExpression/StringLiteral">
          <xsl:value-of select="ms2pg:QuoteName(ColumnName/IdentifierOrValueExpression/ValueExpression/StringLiteral/@Value)"/>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="SelectSetVariable">
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>INTO</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="SelectSetVariable">
        <xsl:if test="position() > 1">
          <xsl:text>,</xsl:text>
          <xsl:call-template name="_LineBreak" />
        </xsl:if>
        <xsl:apply-templates select="Variable" />
      </xsl:for-each>
    </xsl:if>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!--Select clause for for xml-->
  <xsl:template match="SelectElements" mode="ForXml">
    <xsl:text>SELECT </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:if test="following-sibling::ForClause/XmlForClause/Options/XmlForClauseOption[@OptionKind='Root'  and Value/StringLiteral/@Value != '']">
      <xsl:text>xmlelement(name "</xsl:text>
      <xsl:value-of select="following-sibling::ForClause/XmlForClause/Options/XmlForClauseOption[@OptionKind='Root']/Value/StringLiteral/@Value"/>
      <xsl:text>", </xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
    </xsl:if>
    <xsl:text>xmlagg(</xsl:text>
    <xsl:if test="following-sibling::ForClause/XmlForClause/Options/XmlForClauseOption[@OptionKind='Path' and Value/StringLiteral/@Value != '']">
      <xsl:text>xmlelement(name "</xsl:text>
      <xsl:value-of select="following-sibling::ForClause/XmlForClause/Options/XmlForClauseOption[@OptionKind='Path']/Value/StringLiteral/@Value"/>
      <xsl:text>", </xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
    </xsl:if>
    
     <!--Attributes-->
    <xsl:if test="*[ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@')]">
      <xsl:text>xmlattributes (</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="*[ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@')]">
        <xsl:if test="position() > 1">
          <xsl:call-template name="_LineBreak" />
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="ColumnName">
            <xsl:choose>
              <xsl:when test="ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@')">
                <xsl:apply-templates select="Expression" />
                <xsl:text> AS </xsl:text>
                <xsl:value-of select="ms2pg:QuoteName(ms2pg:Replace(ColumnName/IdentifierOrValueExpression/@Value, '@', ''))"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>
    </xsl:if>
    
    <!--Values-->
    <xsl:if test="*[not(ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@')) and not(Expression/ColumnReferenceExpression) and not(ColumnName)]">
      <xsl:if test="*[ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@')]">
        <xsl:call-template name="_LineBreak" />
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:for-each select="*[not(ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@'))and not(Expression/ColumnReferenceExpression) and not(ColumnName)]">
        <xsl:if test="position() > 1">
          <xsl:call-template name="_LineBreak" />
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="Expression" />
      </xsl:for-each>
    </xsl:if>
    
     <!--Elements-->
    <xsl:if test="*[not(ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@')) and (Expression/ColumnReferenceExpression or ColumnName)]">
      <xsl:if test="*[ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@') or not(Expression/ColumnReferenceExpression) and not(ColumnName)]">
        <xsl:call-template name="_LineBreak" />
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:text>xmlforest (</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:for-each select="*[not(ms2pg:StartsWith(ColumnName/IdentifierOrValueExpression/@Value, '@')) and (Expression/ColumnReferenceExpression or ColumnName)]">
        <xsl:if test="position() > 1">
          <xsl:call-template name="_LineBreak" />
          <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="ColumnName">
            <xsl:choose>
              <xsl:when test="ColumnName/IdentifierOrValueExpression[@Value and not (ms2pg:Contains(@Value, '/'))]">
                <xsl:apply-templates select="Expression" />
                <xsl:text> AS </xsl:text>
                <xsl:value-of select="ms2pg:QuoteName(ColumnName/IdentifierOrValueExpression/@Value)"/>
              </xsl:when>
              <xsl:when test="ColumnName/IdentifierOrValueExpression[@Value and ms2pg:Contains(@Value, '/')]">
                <xsl:for-each select ="ms2pg:SplitString(ColumnName/IdentifierOrValueExpression/@Value, '/')/root/*[position()>1]">
                  <xsl:choose>
                    <xsl:when test="ms2pg:StartsWith(text(), '@')">
                      <xsl:text>xmlattributes (</xsl:text>                      
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:text>xmlelement (name "</xsl:text>
                      <xsl:value-of select="text()"/>
                      <xsl:text>", </xsl:text>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
                <xsl:apply-templates select="Expression" />
                <xsl:for-each select ="ms2pg:SplitString(ColumnName/IdentifierOrValueExpression/@Value, '/')/root/*[position()>1]">
                  <xsl:if test="ms2pg:StartsWith(text(), '@')">
                    <xsl:text> AS </xsl:text>
                    <xsl:value-of select="ms2pg:Replace(text(), '@', '')"/>
                  </xsl:if>
                  <xsl:text>)</xsl:text>
                </xsl:for-each>
                <xsl:text> AS </xsl:text>
                <xsl:value-of select="ms2pg:SplitString(ColumnName/IdentifierOrValueExpression/@Value, '/')/root/*[1]"/>
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="Expression" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>
    </xsl:if>
      
    <xsl:if test="following-sibling::ForClause/XmlForClause/Options/XmlForClauseOption[@OptionKind='Path' and Value/StringLiteral/@Value != '']">
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>
    </xsl:if>

    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>)</xsl:text>
    <xsl:if test="following-sibling::ForClause/XmlForClause/Options/XmlForClauseOption[@OptionKind='Root'  and Value/StringLiteral/@Value != '']">
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!-- From clause -->
  <xsl:template match="FromClause">
    <xsl:text>FROM </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="TableReferences" />
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!-- Group by clause -->
  <xsl:template match="GroupByClause">
    <xsl:text>GROUP BY </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="GroupingSpecifications/ExpressionGroupingSpecification">
      <xsl:if test="position() > 1">
        <xsl:call-template name="_LineBreak" />
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="Expression" />
    </xsl:for-each>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>


  <!-- Having clause -->
  <xsl:template match="HavingClause">
    <xsl:text>HAVING </xsl:text>
    <xsl:apply-templates select="SearchCondition" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!-- Order by clause -->
  <xsl:template match="OrderByClause">
    <xsl:text>ORDER BY </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="OrderByElements"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
  </xsl:template>


  <xsl:template match="TableReferences">
    <xsl:for-each select="*">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
        <xsl:call-template name="_LineBreak" />
      </xsl:if>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="TableReference|FirstTableReference|SecondTableReference">
    <xsl:apply-templates select="NamedTableReference|QualifiedJoin|UnqualifiedJoin|QueryDerivedTable|SchemaObjectFunctionTableReference|VariableTableReference|VariableMethodCallTableReference"/>
  </xsl:template>

  <xsl:template match="QueryDerivedTable">
    <xsl:text>(</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="QueryExpression"/>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>)</xsl:text>
    <xsl:call-template name="_IndentDec" />
    <xsl:if test="Alias/node()">
      <xsl:text> AS </xsl:text>
      <xsl:apply-templates select="Alias/Identifier"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="InlineDerivedTable">
    <xsl:text>( VALUES</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="RowValues/RowValue">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
        <xsl:call-template name="_LineBreak" />
      </xsl:if>
      <xsl:text>(</xsl:text>
      <xsl:for-each select="ColumnValues/*">
        <xsl:if test="position() > 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:text>)</xsl:text>
    </xsl:for-each>
    <xsl:text>)</xsl:text>
    <xsl:if test="Alias/node()">
      <xsl:text> AS </xsl:text>
      <xsl:apply-templates select="Alias/Identifier"/>
    </xsl:if>
    <xsl:if test="Columns/node()">
      <xsl:text>(</xsl:text>
      <xsl:for-each select="Columns/Identifier">
        <xsl:if test="position() > 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ValuesInsertSource">
    <xsl:text> VALUES </xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:for-each select="RowValues/RowValue">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
        <xsl:call-template name="_LineBreak" />
      </xsl:if>
      <xsl:text>(</xsl:text>
      <xsl:for-each select="ColumnValues/*">
        <xsl:if test="position() > 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <xsl:text>)</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="NamedTableReference">

    <xsl:choose>
      <xsl:when test="SchemaObject">
        <xsl:apply-templates select="SchemaObject" />
      </xsl:when>
      <xsl:when test="QueryExpression">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="*"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <xsl:when test="FirstTableReference|SecondTableReference">
        <xsl:call-template name="_IndentInc" />
        <xsl:call-template name="_LineBreak" />
        <xsl:apply-templates select="*" />
        <xsl:call-template name="_IndentDec" />
        <xsl:call-template name="_LineBreak" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/*Unknown table reference*/</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="NamedTableReference/SchemaObject" />
    <xsl:if test="Alias/node()">
      <xsl:text> AS </xsl:text>
      <xsl:apply-templates select="Alias/Identifier" />
    </xsl:if>
  </xsl:template>

  <!-- Join clause -->
  <xsl:template match="QualifiedJoin|UnqualifiedJoin">
    <xsl:variable name="update_target">
      <xsl:apply-templates select="ancestor::UpdateSpecification/Target/NamedTableReference/SchemaObject/SchemaObjectName/Identifiers"/>
    </xsl:variable>
    <xsl:if test="not (FirstTableReference/NamedTableReference/Alias/Identifier/@Value = $update_target)">
      <xsl:apply-templates select ="FirstTableReference" />
    </xsl:if>
    <xsl:call-template name="_LineBreak" />
    <xsl:if test="not (SecondTableReference/NamedTableReference/Alias/Identifier/@Value = $update_target) and not (FirstTableReference/NamedTableReference/Alias/Identifier/@Value = $update_target)">
      <xsl:choose>
        <xsl:when test="@QualifiedJoinType='LeftOuter'">
          <xsl:text>LEFT JOIN </xsl:text>
        </xsl:when>
        <xsl:when test="@QualifiedJoinType='RightOuter'">
          <xsl:text>RIGHT JOIN </xsl:text>
        </xsl:when>
        <xsl:when test="@QualifiedJoinType='FullOuter'">
          <xsl:text>FULL JOIN </xsl:text>
        </xsl:when>
        <xsl:when test="@UnqualifiedJoinType='CrossJoin'">
          <xsl:text>CROSS JOIN </xsl:text>
        </xsl:when>
        <xsl:when test="@QualifiedJoinType='Inner'">
          <xsl:text>INNER JOIN </xsl:text>
        </xsl:when>
        <xsl:when test="@UnqualifiedJoinType='CrossApply'">
          <xsl:text>INNER JOIN LATERAL </xsl:text>
        </xsl:when>
        <xsl:when test="@UnqualifiedJoinType='OuterApply'">
          <xsl:text>LEFT JOIN LATERAL </xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>UNKNOWN TYPE OF JOIN</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select ="SecondTableReference" />
      <xsl:if test="SearchCondition or @UnqualifiedJoinType='CrossApply' or @UnqualifiedJoinType='OuterApply'">
        <xsl:text> ON </xsl:text>
        <xsl:choose>
          <xsl:when test="@UnqualifiedJoinType='CrossApply' or @UnqualifiedJoinType='OuterApply'">
            <xsl:text> true  </xsl:text>
          </xsl:when>
        </xsl:choose>
        <xsl:apply-templates select="SearchCondition" />
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- From clause -->
  <xsl:template match="WhereClause">
    <xsl:variable name="update_target">
      <xsl:apply-templates select="ancestor::UpdateSpecification/Target/NamedTableReference/SchemaObject/SchemaObjectName/Identifiers"/>
    </xsl:variable>
    <xsl:text>WHERE </xsl:text>
    <xsl:if test="ancestor::UpdateSpecification//NamedTableReference/Alias/Identifier/@Value = $update_target">
      <xsl:text>(</xsl:text>
    </xsl:if>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:apply-templates select="SearchCondition" />
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:if test="ancestor::UpdateSpecification//NamedTableReference/Alias/Identifier/@Value = $update_target">
      <xsl:text>)</xsl:text>
      <xsl:text> AND </xsl:text>
      <xsl:apply-templates select="ancestor::UpdateSpecification//NamedTableReference[Alias/Identifier/@Value = $update_target]/ancestor::*[2]/SearchCondition"/>
    </xsl:if>
  </xsl:template>

  <!-- From clause -->
  <xsl:template match="SchemaObject">
    <xsl:apply-templates select ="SchemaObjectName/Identifiers" />
  </xsl:template>

  <xsl:template match="SchemaObjectFunctionTableReference">
    <xsl:apply-templates select="SchemaObject"/>
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="Parameters"/>
    <xsl:text>)</xsl:text>
    <xsl:if test="Alias/Identifier">
      <xsl:text> AS </xsl:text>
      <xsl:apply-templates select="Alias/Identifier"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="TopRowFilter">
    <xsl:call-template name="_LineBreak" />
    <xsl:text>LIMIT </xsl:text>
    <xsl:apply-templates select="Expression"/>
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <xsl:template match="Select">
    <xsl:apply-templates select="BinaryQueryExpression|QuerySpecification"/>
  </xsl:template>

  <xsl:template match="WithCtesAndXmlNamespaces">
    <xsl:text>WITH </xsl:text>
    <xsl:if test="//TableReferences/NamedTableReference/SchemaObject/SchemaObjectName/Identifiers/Identifier[@Value = ancestor::CommonTableExpressions/CommonTableExpression/ExpressionName/Identifier/@Value]">
      <xsl:text>RECURSIVE </xsl:text>
    </xsl:if>
    <xsl:call-template name="_IndentInc" />
    <xsl:for-each select="CommonTableExpressions/CommonTableExpression">
      <xsl:if test="position()>1">
        <xsl:call-template name="_LineBreak" />
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="ExpressionName/Identifier"/>
      <xsl:text> AS (</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:apply-templates select="QueryExpression"/>
      <xsl:call-template name="_IndentDec" />
      <xsl:text>)</xsl:text>
      <xsl:call-template name="_LineBreak" />
    </xsl:for-each>
    <xsl:call-template name="_IndentDec" />
  </xsl:template>

</xsl:stylesheet>