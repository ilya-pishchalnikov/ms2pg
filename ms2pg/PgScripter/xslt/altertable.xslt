<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- Alter table add statement -->
  <xsl:template match="AlterTableAddTableElementStatement">
    <xsl:text>ALTER TABLE </xsl:text>
    <xsl:apply-templates select="SchemaObjectName" />
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="Definition/TableConstraints" />
    <!-- TODO: Constraints definitions -->
    <!-- TODO: Column definitions -->
    <!-- TODO: Indexes -->
  </xsl:template>

  <!-- Alter table add constraints -->
  <xsl:template match="TableConstraints">
    <xsl:choose>
      <xsl:when test="'./DefaultConstraintDefinition'">
        <xsl:apply-templates select="DefaultConstraintDefinition" />
      </xsl:when>
      <!-- TODO: Other constraints definitions -->
      <xsl:otherwise>
        <xsl:call-template name="_UnknownToken" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Default constraint -->
  <xsl:template match="DefaultConstraintDefinition">
    <xsl:text>ALTER COLUMN </xsl:text>
    <xsl:value-of select="./Column/@Value" />    
    <xsl:text> SET DEFAULT </xsl:text>
    <xsl:apply-templates select="./Expression" />
  </xsl:template>

</xsl:stylesheet>