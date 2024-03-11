<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
>
  <xsl:import href="settings.xslt" />
  <xsl:import href="sqlnullstatement.xslt"/>
  <xsl:output omit-xml-declaration="yes" indent="yes"/>


  <!-- Сообщение о неизвестном узле -->
  <xsl:template name ="_UnknownToken">
    <xsl:call-template name="_LineBreak" />
    <xsl:text>/********************** UNKNOWN TOKEN '</xsl:text>
    <xsl:value-of select="local-name()"/>
    <xsl:text>'**********************/;</xsl:text>
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!-- Увеличить отступ -->
  <xsl:template name ="_IndentInc">
    <xsl:text>{{Indent++}}</xsl:text>
  </xsl:template>

  <!-- Уменьшить отступ -->
  <xsl:template name ="_IndentDec">
    <xsl:text>{{Indent--}}</xsl:text>
  </xsl:template>

  <!-- Перенос строки -->
  <xsl:template name ="_LineBreak">
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

   <!-- End of Statement -->
  <xsl:template name ="_EndOfStatement">
    <xsl:text>;&#10;</xsl:text>
  </xsl:template>


   <!-- Object Identifier dbo_ObjectName -->
  <xsl:template match="SchemaObjectName">
    <xsl:if test="SchemaIdentifier">
      <xsl:value-of select="SchemaIdentifier/@Value"/>
      <xsl:text>_</xsl:text>
    </xsl:if>
    <xsl:if test="BaseIdentifier">
      <xsl:value-of select="BaseIdentifier/@Value"/>
    </xsl:if>
    <xsl:call-template name = "_LineBreak" />
  </xsl:template>

  <!-- Data type -->
  <xsl:template match="DataType">
    <xsl:variable name="datatype">
      <xsl:apply-templates select="Name/Identifiers/Identifier/@Value" />
    </xsl:variable>
    <xsl:choose >
      <xsl:when test="boolean(ancestor::ColumnDefinition/IdentityOptions)">SERIAL</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='BIGINT'">BIGINT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='BINARY'">BYTEA</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='BIT'">BOOLEAN</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='CHAR'">CHAR</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='CHARACTER'">CHARACTER</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='DATE'">DATE</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='DATETIME2'">TIMESTAMP</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='DATETIME'">TIMESTAMP(3)</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='DATETIMEOFFSET'">TIMESTAMPTZ</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='DEC'">DEC</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='DECIMAL'">DECIMAL</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='DOUBLE PRECISION'">DOUBLE PRECISION</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='FLOAT'">FLOAT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='IMAGE'">BYTEA</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='INT'">INT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='INTEGER'">INTEGER</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='MONEY'">MONEY</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='NCHAR'">CHAR</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='NTEXT'">TEXT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='NUMERIC'">NUMERIC</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='NVARCHAR' and Parameters/MaxLiteral">TEXT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='NVARCHAR' and not (Parameters/MaxLiteral)">VARCHAR</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='REAL'">REAL</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='ROWVERSION'">BYTEA</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='SMALLDATETIME'">TIMESTAMP(0)</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='SMALLINT'">SMALLINT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='SMALLMONEY'">MONEY</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='TEXT'">TEXT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='TIME'">TIME</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='TIMESTAMP'">BYTEA</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='TINYINT'">INT2</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='UNIQUEIDENTIFIER'">UUID</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='VARBINARY'">BYTEA</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='VARCHAR' and Parameters/MaxLiteral">TEXT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='VARCHAR' and not (Parameters/MaxLiteral)">VARCHAR</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='FIELDHIERARCHYID'">BIGINT</xsl:when>
      <xsl:when test="translate($datatype, $lowercase, $uppercase)='XML'">XML</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$datatype" />
      </xsl:otherwise>
    </xsl:choose>
    <xsl:for-each select="Parameters/*">
      <xsl:if test="position() = 1">
        <xsl:text>(</xsl:text>
      </xsl:if>
      <xsl:if test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:value-of select="@Value" />
    </xsl:for-each>
    <xsl:if test="Parameters/*">
      <xsl:text>)</xsl:text>
    </xsl:if>    
  </xsl:template>

  <!-- Идентификатор объекта dbo_ObjectName 
  <xsl:template match="SqlObjectIdentifier">
    <xsl:for-each select="SqlIdentifier">
      <xsl:if test="position() > 1 and not($skip_dbo_in_object_identifiers) or position() > 2 and $skip_dbo_in_object_identifiers ">
        <xsl:text>_</xsl:text>
      </xsl:if>
      <xsl:if test="position() != 1 or @Value != 'dbo' or not ($skip_dbo_in_object_identifiers)">
        <xsl:apply-templates select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
-->

  <!-- Описание идентификатора 
  <xsl:template match="SqlIdentifier">
    <xsl:value-of select="@Value"/>
  </xsl:template>-->

  <!-- Спецификация типа
  <xsl:template match="SqlDataTypeSpecification">
    <xsl:variable name="datatype">
      <xsl:apply-templates select="SqlDataType"/>
    </xsl:variable>
    <xsl:value-of select="$datatype"/>
    <xsl:choose>
      <xsl:when test="$datatype = 'BYTEA' or $datatype = 'TEXT'"/>
      <xsl:when test="($datatype = 'TIMESTAMP' or $datatype = 'TIMESTAMPTZ') and @Argument1 > 6 ">
        <xsl:text>(6)</xsl:text>
      </xsl:when>
      <xsl:when test ="@IsMaximum='True'">
        <xsl:text>(max)</xsl:text>
      </xsl:when>
      <xsl:when test ="@Argument1">
        <xsl:text>(</xsl:text>
        <xsl:value-of select="@Argument1"/>
        <xsl:if test= "@Argument2">
          <xsl:text>,</xsl:text>
          <xsl:value-of select="@Argument2"/>
        </xsl:if>
        <xsl:text>)</xsl:text>
      </xsl:when>
    </xsl:choose>
  </xsl:template>-->

</xsl:stylesheet>
