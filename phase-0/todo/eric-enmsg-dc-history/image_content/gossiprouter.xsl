<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns="urn:jboss:domain:1.7"
                xmlns:jgroups1.1="urn:jboss:domain:jgroups:1.1"
                exclude-result-prefixes="jgroups1.1">
  <xsl:output method="xml" indent="yes" />
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>
  
  <xsl:param name="defaultStack" select="'${jgstack:udp}'"/>
  
  <xsl:template match="//*[local-name()='subsystem' and namespace-uri()='urn:jboss:domain:jgroups:1.1']">
    <xsl:copy>
      <xsl:attribute name="default-stack">
        <xsl:value-of select="$defaultStack"/>
      </xsl:attribute>
      <xsl:if test="not(//*[local-name()='stack' and @name='tcp-gossip'])">
      <stack name="tcp-gossip" xmlns="urn:jboss:domain:jgroups:1.1">
        <transport type="TCP" socket-binding="jgroups-tcp"/>
        <protocol type="TCPGOSSIP">
          <property name="timeout">6000</property>
          <property name="num_initial_members">2</property>
          <property name="initial_hosts">${gossiprouters_for_remoting}</property>
          <property name="sock_conn_timeout">5000</property>
          <property name="sock_read_timeout">3000</property>
        </protocol>
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='MERGE2']" />
        <protocol type="FD_SOCK" socket-binding="jgroups-tcp-fd"/>
        <protocol type="FD"/>
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='VERIFY_SUSPECT']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='pbcast.NAKACK']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='UNICAST2']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='pbcast.STABLE']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='pbcast.GMS']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='UFC']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='MFC']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='FRAG2']" />
        <xsl:copy-of select="jgroups1.1:stack[@name='udp']/jgroups1.1:protocol[@type='RSVP']" />
      </stack>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
 
  <xsl:template match="//*[local-name()='socket-binding-group']">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
      <xsl:if test="not(//*[local-name()='socket-binding' and @name='jgroups-tcp'])">
        <socket-binding name="jgroups-tcp" port="7600"/>
      </xsl:if>
      <xsl:if test="not(//*[local-name()='socket-binding' and @name='jgroups-tcp-fd'])">
        <socket-binding name="jgroups-tcp-fd" port="57600"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
