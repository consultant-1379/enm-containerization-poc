#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

# Set the envar to identify the server.

/bin/cp -f /var/tmp//configure-fileshare.sh /opt/ericsson/com.ericsson.oss.services.cm/
/bin/cp -f /var/tmp/cmserv_register_web_contexts /etc/cron.d/

# increase timeout for jboss
sed -i "s/PG_ONLINE_MAX_RETRIES=60/PG_ONLINE_MAX_RETRIES=1000/g" /ericsson/3pp/jboss/bin/pre-start/check_config_schema_available.sh
sed -i "s/PG_SCHEMA_MAX_RETRIES=10/PG_SCHEMA_MAX_RETRIES=1000/g" /ericsson/3pp/jboss/bin/pre-start/check_config_schema_available.sh

echo "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/
/bin/cp -f /var/tmp/rename_currentxml.sh /ericsson/3pp/jboss/bin/post-start/
/bin/mkdir -p /root/.ssh
/bin/cp /var/tmp/postgres_key.pem /root/.ssh/id_rsa
/bin/chmod 600 /root/.ssh/id_rsa

#CM need to wait till Postgres is up to configure its DB, below check is for Identy mgt database as Postgres creates this on its install
POSTGRES_QUERY_Result=255
while true;
echo "Waiting for postgres database"
do
  /usr/bin/psql -U postgres -h postgresql01 -d idenmgmt -A -t -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'postgre_configuration';" >/tmp/postgrescheck 2>&1
  POSTGRES_QUERY_Result=$(echo $?)
  case ${POSTGRES_QUERY_Result} in
    [0]) echo "Postgres is Available"
         break
       ;;
     *)
       echo "Postgres not yet available, Retrying in 10 sec"
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
  echo "Error in installing config service db"
  exit 1
fi

#TECHNICAL DEBT
#Need to update the CriticalSpaceThreshold value via PIB
/opt/ericsson/PlatformIntegrationBridge/etc/config.py update --app_server_address=cmserv:8080 --name=databaseSpaceCriticalThreshold --value=1000 --scope=GLOBAL

echo "starting service"
echo "Starting enmCertificatesLocal...";/opt/ericsson/ERICcredentialmanagercli/bin/enmCertificatesLocal.sh

#/etc/init.d/vmmonitord start
#/etc/init.d/jboss start

/bin/cp -f /var/tmp/register_web_context.sh  /ericsson/cmserv/scripts/register_web_context.sh
/ericsson/cmserv/scripts/register_web_context.sh

/etc/init.d/crond start
