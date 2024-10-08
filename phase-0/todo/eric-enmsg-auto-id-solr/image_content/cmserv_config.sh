#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

# Set the envar to identify the server.
service rsyslog start

yum install -y ERICenmsgcmservice_CXP9031573

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

#CM need to wait till Postgres is up to configure its DB, below check is for Identy mgt database as Postgres creates this on its install
POSTGRES_QUERY_Result=255
while true;
logger "Waiting for postgres database"
do
  /usr/bin/psql -U postgres -h postgresql01 -d idenmgmt -A -t -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'postgre_configuration';" >/tmp/postgrescheck 2>&1
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
ssh -o 'StrictHostKeyChecking no' -tt cloud-user@postgresql01 "sudo yum install -y ERICcmconfigservicedb_CXP9031954;
sudo su - postgres -c 'createdb configds';
sudo /opt/ericsson/ERICcmconfigservicedb_CXP9031954/\$(ls -1 /opt/ericsson/ERICcmconfigservicedb_CXP9031954/ | egrep install_config_service_db[[:digit:]]{4}.sh | tail -1);"
if [ $(echo "${PIPESTATUS[@]}" | tr -s ' ' + | bc) -ne 0 ]; then
  logger "Error in installing config service db"
  exit 1
fi

#TECHNICAL DEBT
#Need to update the CriticalSpaceThreshold value via PIB
/opt/ericsson/PlatformIntegrationBridge/etc/config.py update --app_server_address=cmserv:8080 --name=databaseSpaceCriticalThreshold --value=1000 --scope=GLOBAL

logger "starting service"
echo "Starting enmCertificatesLocal...";/opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh

/etc/init.d/vmmonitord start
/etc/init.d/jboss start

/bin/cp -f /var/tmp/register_web_context.sh  /ericsson/cmserv/scripts/register_web_context.sh
/ericsson/cmserv/scripts/register_web_context.sh
