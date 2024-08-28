#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
service rsyslog start

# Set up host file
source /ericsson/tor/data/global.properties
echo -e "$(hostname --ip-address) sso-instance-1 sso-instance-1.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "10.99.99.99  sso-instance-2 sso-instance-2.${UI_PRES_SERVER}" >> /etc/hosts

yum install -y pyOpenSSL
yum install -y ERICenmsgsso_CXP9031582

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf
echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf
echo -e "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap\"" >> /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/MAX_REPEAT_WAIT_SECOND_SSO = 2880/MAX_REPEAT_WAIT_SECOND_SSO = 20/"g /opt/ericsson/sso/bin/python/sso_const.py

logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

logger "replacing neo4j file"
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/
/bin/cp -f /var/tmp/rename_currentxml.sh /ericsson/3pp/jboss/bin/post-start/
/bin/cp -f /var/tmp/update_jgroups_protocolstack.sh /ericsson/3pp/jboss/bin/pre-start-with-exit/

/bin/cp -f /var/tmp/sso_utils.py /opt/ericsson/sso/bin/python/
/bin/cp -f /var/tmp/sso_class.py /opt/ericsson/sso/bin/python/
/bin/cp -f /var/tmp/install_sso.py /opt/ericsson/sso/bin/python/

logger "starting service"
echo "Starting enmCertificatesLocal...";/opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh
/etc/init.d/vmmonitord start
/etc/init.d/jboss start

