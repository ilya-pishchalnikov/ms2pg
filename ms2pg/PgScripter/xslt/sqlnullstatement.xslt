<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
    xmlns:fn="urn:custom"
>
  <!-- Обрабатываем по токенам стейтменты, которые не распознал парсер -->
  <xsl:template name="_SqlNullStatement">
    <xsl:for-each select="Tokens/Token[@type != 'LEX_WHITE']">
      <xsl:choose>
        <xsl:when test="@type='TOKEN_ALTER'">
          <xsl:apply-templates select ="_Alter" mode="_ParseSqlNullStatement" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="_UnknownToken" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- Обрабатываем стейтмент ALTER -->
  <xsl:template match ="_Alter" mode="_ParseSqlNullStatement">
    <xsl:choose>
      <xsl:when test="following-sibling::Token[@type != 'LEX_WHITE']/@type = 'TOKEN_TABLE'">
        <xsl:call-template name="_AlterTable" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="_UnknownToken" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Обрабатываем стейтмент ALTER TABLE -->
  <xsl:template name="_AlterTable">
    <xsl:text>TABLE </xsl:text>
    <xsl:choose>
      <xsl:when test="following-sibling::Token[@type != 'LEX_WHITE']/@type = 'TOKEN_ID'">
        <xsl:call-template name="_Identifier">
          <xsl:with-param name = "id-part-number" select="1"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="_UnknownToken" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Обрабатываем стейтмент ALTER TABLE TABLE_IDENTIFIER -->
  <xsl:template name="_Identifier">
    <xsl:param name="id-part-number" />
    <xsl:value-of select="$id-part-number"/>
    <xsl:choose>
      <xsl:when test="following-sibling::Token[@type != 'LEX_WHITE']/@type = '.'">
        <xsl:call-template name="_IdentifierDivider">
          <xsl:with-param name = "id-part-number" select="$id-part-number + 1" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="_UnknownToken" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Обрабатываем стейтмент ALTER TABLE TABLE_IDENTIFIER -->
  <xsl:template name="_IdentifierDivider">
    <xsl:param name="id-part-number" />
    <xsl:value-of select="$id-part-number"/>
    <xsl:choose>
      <xsl:when test="following-sibling::Token[@type != 'LEX_WHITE']/@type = 'TOKEN_ID'">
        <xsl:call-template name="_Identifier">
          <xsl:with-param name = "id-part-number" select="$id-part-number + 1" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="_UnknownToken" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>



  <!-- Обрабатываем ситуацию, когда токен не предусмотрен -->
  <xsl:template name="_UnknownToken">
    <xsl:text>/*UNKNOWN TOKEN </xsl:text>
    <xsl:value-of select="@type"/>
    <xsl:text>*/</xsl:text>
  </xsl:template>

</xsl:stylesheet>


