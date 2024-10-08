#!/bin/bash
/bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties


# Set the envar to identify the server.
service rsyslog start

logger "package install"
yum install -y ERICenmsgmsfm_CXP9031660

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf
echo -e "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap\"" >> /ericsson/3pp/jboss/bin/standalone.conf

echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf


logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

logger "bugs for check service availabilityi workaround"
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/
/bin/cp -f /var/tmp/rename_currentxml.sh /ericsson/3pp/jboss/bin/post-start/


logger "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/

#The below two scripts are needed until https://gerrit.ericsson.se/#/c/3309850/ is merged
/bin/cp -f /var/tmp/gossiprouter.xsl /ericsson/3pp/jboss/standalone/data/gossiprouter/gossiprouter.xsl
/bin/cp -f /var/tmp/update_jgroups_protocolstack.sh /ericsson/3pp/jboss/bin/pre-start-with-exit/update_jgroups_protocolstack.sh

logger "copying enmCertficatesLocal"
/bin/cp -f /var/tmp/enmCertificatesLocal.sh /opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh
echo "Starting enmCertificatesLocal...";/opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh

logger "starting service"
/etc/init.d/jboss start
