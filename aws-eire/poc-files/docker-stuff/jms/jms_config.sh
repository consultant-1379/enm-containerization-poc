#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

# Set the envar to identify the server.
service rsyslog start

yum install -y ERICenmsgjmsserver_CXP9031572


# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
#sed -i "s/jms_bind_address.*/jms_bind_address=${IP_ADDRESS}/g" /ericsson/tor/data/global.properties

sed -i "s/\${hostname --ip-address}/\$(hostname --ip-address)/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/\${hostname --ip-address}/\$(hostname --ip-address)/g" /ericsson/3pp/jboss/bin/bin/standalone.conf
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf
# reducing max memory size.
sed 's/MEMORY_MAX=.*/MEMORY_MAX=6144/g'
# adding cgroups flags so jvm adheres to resource limits
echo -e "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap\"" >> /ericsson/3pp/jboss/bin/standalone.conf

echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf

logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

logger "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
/bin/cp -f /var/tmp/rename_currentxml.sh /ericsson/3pp/jboss/bin/post-start/
/etc/init.d/vmmonitord start
/etc/init.d/jboss start
