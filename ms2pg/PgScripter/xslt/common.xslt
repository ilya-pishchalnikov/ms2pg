<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
>
  <xsl:import href="settings.xslt" />
  <xsl:output omit-xml-declaration="yes" indent="yes" />


  <!-- Сообщение о неизвестном узле -->
  <xsl:template name="_UnknownToken">
    <xsl:call-template name="_LineBreak" />
    <xsl:text>/********************** UNKNOWN TOKEN '</xsl:text>
    <xsl:value-of select="local-name()" />
    <xsl:text>'**********************/</xsl:text>
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

  <!-- Increment indent -->
  <xsl:template name="_IndentInc">
    <xsl:text>{{Indent++}}</xsl:text>
  </xsl:template>

  <!-- Decrement indent -->
  <xsl:template name="_IndentDec">
    <xsl:text>{{Indent--}}</xsl:text>
  </xsl:template>

  <!-- Statement begin mark -->
  <xsl:template name="_StatementBegin">
    <xsl:text>{{StatementBegin:</xsl:text>
    <xsl:value-of select="local-name()" />
    <xsl:text>}}</xsl:text>
  </xsl:template>

  <!-- Statement end mark -->
  <xsl:template name="_StatementEnd">
    <xsl:text>{{StatementEnd:</xsl:text>
    <xsl:value-of select="local-name()" />
    <xsl:text>}}</xsl:text>
  </xsl:template>

  <!-- Перенос строки -->
  <xsl:template name="_LineBreak">
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- End of Statement -->
  <xsl:template name="_EndOfStatement">
    <xsl:text>;&#10;</xsl:text>
  </xsl:template>

  <!-- start of code block -->
  <xsl:template name="_DoBegin">
    <xsl:text>DO</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>$$</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>BEGIN</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:call-template name="_IndentInc" />
  </xsl:template>

    <!-- end of code block -->
  <xsl:template name="_DoEnd">
    <xsl:call-template name="_LineBreak" />
    <xsl:call-template name="_IndentDec" />
    <xsl:text>END;</xsl:text>
    <xsl:call-template name="_LineBreak" />
    <xsl:text>$$</xsl:text>
    <xsl:call-template name="_LineBreak" />
  </xsl:template>

</xsl:stylesheet>