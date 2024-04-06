<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl"
>

  <xsl:variable name="skip_dbo_in_object_identifiers" select="true()" />
  <xsl:variable name="create_table_if_not_exists" select="true()" />
  <xsl:variable name="create_primary_key_if_not_exists" select="true()" />
  <xsl:variable name="move_alter_table_to_postprocess" select="true()" />

  <!-- Case changing variables -->
  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

  <xsl:variable name="default_schema_name" select="'dbo'"/>
  
</xsl:stylesheet>
