#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
# Set the envar to identify the server.
service rsyslog start


yum install -y ERICenmsgmedrouter_CXP9031575

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf
echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf
echo -e "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap\"" >> /ericsson/3pp/jboss/bin/standalone.conf

logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

logger "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/
/bin/cp -f /var/tmp/rename_currentxml.sh /ericsson/3pp/jboss/bin/post-start/
#The below is needed until https://gerrit.ericsson.se/#/c/3309850/ is merged
/bin/cp -f /var/tmp/gossiprouter.xsl /ericsson/3pp/jboss/standalone/data/gossiprouter/gossiprouter.xsl

logger "starting service"
/etc/init.d/vmmonitord start
/etc/init.d/jboss start
