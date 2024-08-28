<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:jms="urn:jboss:domain:messaging:1.4">

    <xsl:output method="xml" indent="yes" />

    <xsl:variable name="destinations_file" select="document($jms_destinations_file)" />
    <xsl:variable name="standalone_file" select="document($jboss_config_file)" />
    <xsl:variable name="ns_msg" select="'urn:jboss:domain:messaging:1.4'" />

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
    </xsl:template>

    <!-- If diverts exists, copy and add all divert from given xml -->
    <xsl:template match="//jms:diverts">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" />
            <xsl:call-template name="copy-destinations" />
        </xsl:copy>
    </xsl:template>

    <!-- copy from xml if the divert don't exist -->
    <xsl:template name="copy-destinations">
        <xsl:for-each select="$destinations_file/jms:diverts/jms:divert">
            <xsl:variable name="destination_name" select="@name" />
            <xsl:if test="not($standalone_file//jms:diverts/jms:divert[@name=$destination_name])">
                <xsl:apply-templates select="." />
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
