#!/bin/bash

# Set the envar to identify the server.
service rsyslog start

yum install -y ERICenmsgsps_CXP9031956.noarch
yum install -y postgresql92-postgresql

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=\$DEFAULT_IP/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf
echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf

logger "replacing neo4j file"
/bin/cp -f /var/tmp/setup-neo4j-subsystem.sh /ericsson/3pp/jboss/bin/pre-start/
logger "replacing gossiprouter.xsl"
/bin/cp -f /var/tmp/gossiprouter.xsl /ericsson/3pp/jboss/standalone/data/gossiprouter/gossiprouter.xsl
#Remove the file to tag a previous SPS correct restart if it exists
rm -f /ericsson/tor/data/spsrestartcomplete.txt

#Postgres
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
#workaround #1 sps scripts
#Configure Postgres, ssh to be removed with a better solution
ssh -o 'StrictHostKeyChecking no' -tt cloud-user@postgresql01 "sudo yum install -y ERICpkiservicedb_CXP9031995;\n
sudo su - postgres -c 'createdb pkicoredb';\n
sudo bash /ericsson/pki_postgres/db/pkicore/install_update_pkicore_db.sh;\n
sudo su - postgres -c 'createdb pkimanagerdb';\n
sudo bash /ericsson/pki_postgres/db/pkimanager/install_update_pkimanager_db.sh;\n
sudo su - postgres -c 'createdb pkirascepdb';\n
sudo bash /ericsson/pki_postgres/db/pkirascep/install_update_pkirascep_db.sh;\n
sudo su - postgres -c 'createdb pkiracmpdb';\n
sudo bash /ericsson/pki_postgres/db/pkiracmp/install_update_pkiracmp_db.sh;\n
sudo su - postgres -c 'createdb pkiratdpsdb';\n
sudo bash /ericsson/pki_postgres/db/pkiratdps/install_update_pkiratdps_db.sh;\n
sudo su - postgres -c 'createdb pkicdpsdb';\n
sudo bash /ericsson/pki_postgres/db/pkicdps/install_update_pkicdps_db.sh;\n
sudo su - postgres -c 'createdb kapsdb';\n
sudo bash /ericsson/pki_postgres/db/kaps/install_update_kaps_db.sh"

logger "starting Jboss... SPS will need manual intervention before service starts correctly [techdebt #2345671"
/etc/rc.local 
