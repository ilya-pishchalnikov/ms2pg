<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:ms2pg="urn:ms2pg"  
>

  <!-- Alter table add statement -->
  <xsl:template match="AlterTableAddTableElementStatement">
    <xsl:variable name="if_exists" select="Definition/TableDefinition/TableConstraints/UniqueConstraintDefinition[@IsPrimaryKey='True']
      and $create_primary_key_if_not_exists" />
    <xsl:if test="$if_exists">      
      <xsl:call-template name="_DoBegin" />
      <xsl:text>IF NOT EXISTS (</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text>SELECT *</xsl:text>
      <xsl:call-template name="_LineBreak" />
      <xsl:text>FROM information_schema.table_constraints</xsl:text>
      <xsl:call-template name="_LineBreak" />
      <xsl:text>WHERE table_name = LOWER('</xsl:text>
      <xsl:apply-templates select="SchemaObjectName" />
      <xsl:text>')</xsl:text>
      <xsl:call-template name="_IndentInc" />
      <xsl:call-template name="_LineBreak" />
      <xsl:text> AND constraint_type = 'PRIMARY KEY') THEN</xsl:text>
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_IndentDec" />
      <xsl:call-template name="_LineBreak" />
    </xsl:if>
    <xsl:text>ALTER TABLE </xsl:text>
    <xsl:apply-templates select="SchemaObjectName" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="Definition/TableDefinition/TableConstraints" />
    <xsl:if test="$if_exists">
      <xsl:call-template name="_IndentDec" />
      <xsl:text>;END IF;</xsl:text>
      <xsl:call-template name="_DoEnd" />
    </xsl:if>
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
          </xsl:if>
          <xsl:apply-templates select="." />
        </xsl:when>
        <xsl:when test="local-name() = 'ForeignKeyConstraintDefinition'">
          <xsl:if test="ancestor::AlterTableAddTableElementStatement">
            <xsl:text>ADD </xsl:text>
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
    <xsl:text>(</xsl:text>
    <xsl:apply-templates select="Columns" />
    <xsl:text>)</xsl:text>
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

</xsl:stylesheet>