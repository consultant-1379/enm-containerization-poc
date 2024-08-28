#!/bin/bash

# Set the envar to identify the server.
service rsyslog start


yum install -y ERICenmsgmedcore_CXP9033047.noarch

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf

logger "replacing neo4j file"
/bin/cp -f setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
logger "replacing gossiprouter.xsl"
/bin/cp -f gossiprouter.xsl /ericsson/3pp/jboss/standalone/data/gossiprouter/gossiprouter.xsl
