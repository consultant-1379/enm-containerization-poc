#!/bin/bash

# Set the envar to identify the server.
service rsyslog start


yum install -y ERICenmsgsecurityservice_CXP9031732

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf

echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf

logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh


logger "BUG on check_wfsdb.py"
sed -i "s/db_name=get_database_name()/db_name=\'wfsdb_secserv\'/g" /ericsson/3pp/jboss/bin/pre-start/check_wfsdb.py

logger "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/
#logger "replacing gossiprouter.xsl"
#/bin/cp -f /var/tmp/gossiprouter.xsl /ericsson/3pp/jboss/standalone/data/gossiprouter/gossiprouter.xsl
/bin/rm -f /opt/ericsson/com.ericsson.oss.services.security.identitymgmt.generic-identity-mgmt-service/generic-identity-mgmt-service-ear*
/bin/cp -f /var/tmp/generic-identity-mgmt-service-ear-1.55.2-SNAPSHOT.ear /opt/ericsson/com.ericsson.oss.services.security.identitymgmt.generic-identity-mgmt-service/



logger "starting service"
echo "Starting enmCertificatesLocal...";/opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh
#/etc/rc.local
