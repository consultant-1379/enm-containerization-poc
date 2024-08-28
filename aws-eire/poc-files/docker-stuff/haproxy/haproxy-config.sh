#!/bin/bash
/bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties


# Set up host file
source /ericsson/tor/data/global.properties
echo -e "$(hostname --ip-address) haproxy sso.${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "$(hostname --ip-address) ${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "${SSO_SERVICE_HOST} sso-instance-1.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "${HTTPD_INSTANCE_1_SERVICE_HOST} httpd-instance-1" >> /etc/hosts

# Set the envar to identify the server.
service rsyslog start

yum install -y ERICenmsghaproxy_CXP9031977.noarch
/bin/cp -f /var/tmp/haproxy-ext.cfg.template /ericsson/3pp/haproxy/data/config/

/etc/init.d/haproxy-ext start
