#!/bin/bash

# Set the envar to identify the server.
service rsyslog start

# Set up host file
source /ericsson/tor/data/global.properties
echo -e "${SSO_SERVICE_HOST} sso-instance-1 sso-instance-1.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "${HTTPD_INSTANCE_1_SERVICE_HOST} httpd-instance-1" >> /etc/hosts


yum install -y ERICenmsgsso_CXP9031582.noarch
#Workaround for systemd/initd check
/bin/cp -f  /ericsson/tor/data/check_service_availability.sh /ericsson/3pp/jboss/bin/check_service_availability.sh
/bin/cp -f  /var/tmp/sso_class.py /opt/ericsson/sso/bin/python/
/bin/cp -f  /var/tmp/install_sso.py /opt/ericsson/sso/bin/python/
logger "replacing gossiprouter.xsl"
#/bin/cp -f /var/tmp/gossiprouter.xsl /ericsson/3pp/jboss/standalone/data/gossiprouter/gossiprouter.xsl
#sed -i "s/$(hostname)/$(hostname) sso-instance-1 sso-instance-1.enmonaws.athtem.eei.ericsson.se/g" /etc/hosts

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf

echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf

logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

sed -i "s/MAX_REPEAT_WAIT_SECOND_SSO = 2880/MAX_REPEAT_WAIT_SECOND_SSO = 20/"g /opt/ericsson/sso/bin/python/sso_const.py
echo "Starting enmCertificatesLocal...";/opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh
