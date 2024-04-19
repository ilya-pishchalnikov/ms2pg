<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:ms2pg="urn:ms2pg"  
>

  <!-- Alter table add statement -->
  <xsl:template match="AlterTableAddTableElementStatement">      
    <xsl:call-template name="_DoBegin" />
    <xsl:text>BEGIN</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>ALTER TABLE </xsl:text>
    <xsl:apply-templates select="SchemaObjectName/Identifiers"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="Definition/TableDefinition/TableConstraints" />
    <xsl:call-template name="_EndOfStatement" />
    <xsl:call-template name="_IndentDec" />    
    <xsl:call-template name="_LineBreak" />
    <xsl:text>EXCEPTION</xsl:text>
    <xsl:call-template name="_IndentInc" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>WHEN duplicate_table THEN RAISE NOTICE 'duplicate table exception';</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>WHEN duplicate_object THEN RAISE NOTICE 'duplicate object exception';</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>WHEN invalid_table_definition  THEN RAISE NOTICE 'invalid table definition exception';</xsl:text>
    <xsl:call-template name="_IndentDec" />
    <xsl:call-template name="_LineBreak" />
    <xsl:text>END;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:call-template name="_DoEnd" />
    <!-- TODO: Column definitions -->
    <!-- TODO: Indexes -->
  </xsl:template>

  <!-- Alter table add constraints -->
  <xsl:template match="TableConstraints">
    <xsl:for-each select="*">
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="local-name() = 'DefaultConstraintDefinition'">
          <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:when test="local-name() = 'UniqueConstraintDefinition'">
          <xsl:if test="ancestor::AlterTableAddTableElementStatement">
            <xsl:text>ADD </xsl:text>
            <xsl:if test="ConstraintIdentifie/Identifier">
              <xsl:text>CONSTRAINT </xsl:text>
              <xsl:apply-templates select="ConstraintIdentifier/Identifier"/>
              <xsl:text> </xsl:text>
            </xsl:if>
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:when test="local-name() = 'ForeignKeyConstraintDefinition'">
          <xsl:if test="ancestor::AlterTableAddTableElementStatement">
            <xsl:text>ADD </xsl:text>
            <xsl:if test="ConstraintIdentifier/Identifier">
              <xsl:text>CONSTRAINT </xsl:text>
              <xsl:apply-templates select="ConstraintIdentifier/Identifier"/>
              <xsl:text> </xsl:text>
            </xsl:if>
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:when test="local-name() = 'CheckConstraintDefinition'">
          <xsl:if test="ancestor::AlterTableAddTableElementStatement">
            <xsl:text>ADD </xsl:text>
            <xsl:if test="ConstraintIdentifier/Identifier">
              <xsl:text>CONSTRAINT </xsl:text>
              <xsl:apply-templates select="ConstraintIdentifier/Identifier"/>
              <xsl:text> </xsl:text>
            </xsl:if>
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:when>     
        <!-- TODO: Other constraints definitions -->
        <xsl:otherwise>
          <xsl:call-template name="_UnknownToken" />
        </xsl:otherwise>
      </xsl:choose>
  </xsl:for-each>
  </xsl:template>

  <!-- Default constraint -->
  <xsl:template match="DefaultConstraintDefinition">
    <xsl:text>ALTER COLUMN </xsl:text>
    <xsl:apply-templates select="Column/Identifier"/>    
    <xsl:text> SET DEFAULT </xsl:text>
    <xsl:apply-templates select="./Expression" />
  </xsl:template>

  <!-- Unique constraint -->
  <xsl:template match="UniqueConstraintDefinition">
    <xsl:apply-templates select="ConstraintIdentifier" />
    <xsl:choose>
      <xsl:when test="@IsPrimaryKey='True'">
        <xsl:text>PRIMARY KEY </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>UNIQUE </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="Columns/node()">
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="Columns" />
    <xsl:text>)</xsl:text>      
    </xsl:if>
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <xsl:template match="Columns">
    <xsl:for-each select="ColumnWithSortOrder">
      <xsl:if test="position() > 1">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="Column/ColumnReferenceExpression/MultiPartIdentifier"/>
    </xsl:for-each>
  </xsl:template>

  <!-- Foreign key constraint -->
  <xsl:template match="ForeignKeyConstraintDefinition">
    <xsl:text>FOREIGN KEY (</xsl:text>
    <xsl:apply-templates select="./Columns/Identifier" />   
    <xsl:text>) REFERENCES </xsl:text>
    <xsl:apply-templates select="ReferenceTableName/SchemaObjectName/Identifiers" />
    <xsl:text> (</xsl:text>
    <xsl:apply-templates select="ReferencedTableColumns/Identifier"/>
    <xsl:text>)</xsl:text>
  </xsl:template>

    <!-- Constraint explicitly name -->
    <xsl:template match="ConstraintIdentifier">
      <xsl:text>CONSTRAINT </xsl:text>
      <xsl:apply-templates select="Identifier"/>  
      <xsl:text> </xsl:text>     
    </xsl:template>

    <xsl:template match="CheckConstraintDefinition">
      <xsl:text>CHECK </xsl:text>
      <xsl:apply-templates select="CheckCondition/*"/>
    </xsl:template>

</xsl:stylesheet>