#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

service rsyslog start
#workaround to run postgres_openidm_populate_db.sh script, make sure psql is available.
yum install -y postgresql92-postgresql
# add sg rpm
yum install -y /var/tmp/ERICenmsgopenidm_CXP9031666*rpm
yum install -y openssh-clients
echo "Copying files..."
/bin/cp -f /var/tmp/common.sh /ericsson/tmp/openidm/bin/
/bin/cp -f /var/tmp/install_steps.sh /ericsson/tmp/openidm/bin/
/bin/mkdir -p /root/.ssh
/bin/cp /var/tmp/postgres_key.pem /root/.ssh/id_rsa
/bin/chmod 600 /root/.ssh/id_rsa

#Postgres
POSTGRES_QUERY_Result=255
while true;
echo "Checking for identity management database"
do
  /opt/rh/postgresql92/root/usr/bin/psql -U postgres -h postgresql01 -d idenmgmt -A -t -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'postgre_configuration';" >>/tmp/postgrescheck 2>&1
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

createdatabase()
{
 ssh -o 'StrictHostKeyChecking no' -tt cloud-user@postgresql01 "sudo su - postgres -c \"psql $1 -c '\q';\""
 if [ $? -ne 0 ]; then
  ssh -o 'StrictHostKeyChecking no' -tt cloud-user@postgresql01 "sudo su - postgres -c 'createdb $1'"
 fi
}

# Creating Openidm Database in postgres
createdatabase openidm
#bash /ericsson/tmp/openidm/bin/postgres_openidm_populate_db.sh

echo "Starting services.."
/etc/init.d/eniq-was-idm-service start
/etc/init.d/vmmonitord start
/etc/init.d/openidm start
