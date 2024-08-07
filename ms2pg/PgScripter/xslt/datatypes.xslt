<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
                xmlns:ms2pg="urn:ms2pg"  
>
  <xsl:template match="DataType">
    <xsl:apply-templates select="SqlDataTypeReference|XmlDataTypeReference|UserDataTypeReference"/>
  </xsl:template>
  <!-- Data type -->
  <xsl:template match="SqlDataTypeReference|XmlDataTypeReference|UserDataTypeReference">
    <xsl:variable name="datatype">
      <xsl:apply-templates select="Name/SchemaObjectName/Identifiers/Identifier/@Value" />
    </xsl:variable>
    <xsl:variable name="pgType">
      <xsl:choose>
        <xsl:when test="boolean(ancestor::ColumnDefinition/IdentityOptions) and not (ancestor::ReturnType/TableValuedFunctionReturnType)">SERIAL</xsl:when>
        <xsl:when test="boolean(ancestor::ColumnDefinition/IdentityOptions) and (ancestor::ReturnType/TableValuedFunctionReturnType)">SERIAL_IN_FUNCTION_RETURN</xsl:when>
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='BIGINT'">BIGINT</xsl:when>
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='BINARY'">BYTEA</xsl:when>
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='BIT'">INT2</xsl:when>
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
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='NTEXT'">
          <xsl:text>TEXT</xsl:text>
        </xsl:when>
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='NUMERIC'">NUMERIC</xsl:when>
        <xsl:when
          test="translate($datatype, $lowercase, $uppercase)='NVARCHAR' and Parameters/MaxLiteral">TEXT</xsl:when>
        <xsl:when
          test="translate($datatype, $lowercase, $uppercase)='NVARCHAR' and not (Parameters/MaxLiteral)">VARCHAR</xsl:when>
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
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='SYSNAME'">VARCHAR(128)</xsl:when>
        <xsl:when
          test="translate($datatype, $lowercase, $uppercase)='VARCHAR' and Parameters/MaxLiteral">
          <xsl:text>TEXT</xsl:text>
        </xsl:when>
        <xsl:when
          test="translate($datatype, $lowercase, $uppercase)='VARCHAR' and not (Parameters/MaxLiteral)">VARCHAR</xsl:when>
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='FIELDHIERARCHYID'">BIGINT</xsl:when>
        <xsl:when test="translate($datatype, $lowercase, $uppercase)='XML'">XML</xsl:when>
        <xsl:when test="./@SqlDataTypeOption='Cursor'">
          <xsl:text>CURSOR FOR (</xsl:text>
          <xsl:call-template name="_IndentInc" />
          <xsl:variable name="cursor_name" select="ms2pg:ToLower(ancestor::*[2]/VariableName/Identifier/@Value)"/>
          <xsl:apply-templates select="//SetVariableStatement[ ms2pg:ToLower(Variable/VariableReference/@Name) = $cursor_name]/CursorDefinition/Select/SelectStatement"/>
          <xsl:call-template name="_IndentDec" />
          <xsl:text>)</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$datatype" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$pgType" />
    <xsl:if test="$pgType!= 'TEXT' and $pgType != 'BYTEA'">
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
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>