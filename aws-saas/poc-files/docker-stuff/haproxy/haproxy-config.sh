#!/bin/bash

# Set up host file
source /ericsson/tor/data/global.properties
echo -e "${HAPROXY_SERVICE_HOST} haproxy sso.${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" > /etc/hosts
echo -e "${HAPROXY_SERVICE_HOST} ${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "${SSO_SERVICE_HOST} sso-instance-1.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "${HTTPD_INSTANCE_1_SERVICE_HOST} httpd-instance-1" >> /etc/hosts

# Set the envar to identify the server.
service rsyslog start

yum install -y ERICenmsghaproxy_CXP9031977.noarch
/bin/cp -f haproxy-ext.cfg.template /ericsson/3pp/haproxy/data/config/

/etc/init.d/haproxy-ext start
