#!/bin/bash

# Set the envar to identify the server.
service rsyslog start

yum install -y ERICenmsgfls_CXP9033307
yum install -y postgresql92-postgresql

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf
echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf


logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

logger "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/

#logger "replacing gossiprouter.xsl"
#/bin/cp -f /var/tmp/gossiprouter.xsl /ericsson/3pp/jboss/standalone/data/gossiprouter/gossiprouter.xsl


#CM need to wait till Postgres is up to configure its DB, below check is for Identy mgt database as Postgres creates this on its install
POSTGRES_QUERY_Result=255
while true;
logger "Waiting for postgres database"
do
  /opt/rh/postgresql92/root/usr/bin/psql -U postgres -h postgresql01 -d idenmgmt -A -t -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'postgre_configuration';" >/tmp/postgrescheck 2>&1
  POSTGRES_QUERY_Result=$(echo $?)
  case ${POSTGRES_QUERY_Result} in
    [0]) logger "Postgres is Available"
         break
       ;;
     *)
       logger "Postgres not yet available, Retrying in 10 sec"
       sleep 10
       ;;
  esac
done

#Configure Postgres
#Create configds and configure
ssh -o 'StrictHostKeyChecking no' -tt cloud-user@postgresql01 "sudo yum install -y ERICflsdb_CXP9033329;
sudo su - postgres -c 'createdb flsdb';
sudo bash /ericsson/fls_postgres/db/fls/\$(ls -1 /ericsson/fls_postgres/db/fls/ | egrep install_fls_db[[:digit:]]{3}.sh | tail -1)"
if [ $(echo "${PIPESTATUS[@]}" | tr -s ' ' + | bc) -ne 0 ]; then
  logger "Error in installing config service db"
  exit 1
fi

logger "starting service"
/etc/rc.local
