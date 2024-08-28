#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

service rsyslog start

yum install -y ERICenmsgsecurityservice_CXP9031732

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf
echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf
echo -e "JAVA_OPTS=\"\$JAVA_OPTS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap\"" >> /ericsson/3pp/jboss/bin/standalone.conf

logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

logger "BUG on check_wfsdb.py"
sed -i "s/db_name=get_database_name()/db_name=\'wfsdb_secserv\'/g" /ericsson/3pp/jboss/bin/pre-start/check_wfsdb.py

logger "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/
/bin/cp -f /var/tmp/rename_currentxml.sh /ericsson/3pp/jboss/bin/post-start/
/bin/rm -f /opt/ericsson/com.ericsson.oss.services.security.identitymgmt.generic-identity-mgmt-service/generic-identity-mgmt-service-ear*
/bin/cp -f /var/tmp/generic-identity-mgmt-service-ear-1.55.2-SNAPSHOT.ear /ericsson/3pp/jboss/standalone/deployments/

/bin/rm -f /ericsson/3pp/jboss/bin/pre-start/copy_cache_replication_config_xml_files.sh 
/bin/rm -f /ericsson/3pp/jboss/bin/pre-start-with-exit/enable_direct_routing.sh

logger "starting service"
echo "Starting enmCertificatesLocal...";/opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh

/etc/init.d/vmmonitord start
/etc/init.d/jboss start
