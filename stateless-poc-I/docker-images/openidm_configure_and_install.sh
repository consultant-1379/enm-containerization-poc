#!/bin/bash

service rsyslog start

yum install -y ERICenmsgopenidm_CXP9031666


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
