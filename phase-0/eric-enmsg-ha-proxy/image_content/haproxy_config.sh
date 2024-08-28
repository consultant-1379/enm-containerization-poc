#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

# Set up host file
source /ericsson/tor/data/global.properties
echo -e "$(hostname --ip-address) haproxy sso.${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "$(hostname --ip-address) ${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "$(getent hosts sso) sso-instance-1.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "${HTTPD_INSTANCE_1_SERVICE_HOST} httpd-instance-1" >> /etc/hosts

# Set the envar to identify the server.
service rsyslog start

yum install -y ERICenmsghaproxy_CXP9031977
/bin/cp -f /var/tmp/haproxy-ext.cfg.template /ericsson/3pp/haproxy/data/config/
/etc/init.d/vmmonitord start
/etc/init.d/haproxy-ext start
