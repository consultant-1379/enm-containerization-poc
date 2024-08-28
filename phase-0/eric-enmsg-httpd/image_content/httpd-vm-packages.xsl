<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:litp="http://www.ericsson.com/litp">
  <xsl:output method="text"/>
  <xsl:template match="/">
    <xsl:for-each select="//litp:vm-service[@id='httpd']//litp:vm-package">
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
