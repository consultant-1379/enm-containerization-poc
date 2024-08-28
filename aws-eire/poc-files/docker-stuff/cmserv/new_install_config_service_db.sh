#!/bin/bash

##########################################################################
# COPYRIGHT Ericsson 2015
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

#source /opt/ericsson/pgsql/etc/postgres01.config

#*Variables*
LOG_FILE=cm-config_install_db.log
INSTALL_PATH=/opt/ericsson/ERICcmconfigservicedb_CXP9031954
PG_SLEEP_INT=5
PG_NUM_TRIES=6
DB=configds
DB_ROLE=config_admin
DB_ROLE_PSW=config_pass
DDL_FILE=Jberet-postgresql.ddl
KILL_EXISTING_CONNECTIONS_FILE=Kill-existing-connections.ddl
OWNERSHIP_FILE=ownership.sql
PG_CLIENT=/opt/rh/postgresql92/root/usr/bin/psql
PG_USER=postgres
PG_HOSTNAME=postgresql01
PG_ROOT=/opt/rh/postgresql92/root/usr/bin/


#*Functions*
#*****************************************************************************#
# Fetches the postgres user password
#*****************************************************************************#
function fetchpassword(){
  PASSKEY=/ericsson/tor/data/idenmgmt/postgresql01_passkey
  GLOBAL_PROPS=/ericsson/tor/data/global.properties

  #Check if files are accessible. If not wait 5 seconds for SFS to be mounted
  if [ ! -f $PASSKEY ]; then
    sleep 5
    if [ ! -f $PASSKEY ]; then
      log1 "Unable to access $PASSKEY"
    fi;
  fi;

  if [ ! -f $GLOBAL_PROPS ]; then
    sleep 5
    if [ ! -f $GLOBAL_PROPS ]; then
      log1 "Unable to access $GLOBAL_PROPS"
    fi;
  fi;

  PASS=postgresql01_admin_password=
  KEY=`grep -i $PASS $GLOBAL_PROPS | awk -F "$PASS" '{print $NF}'`
  PG_PASSWORD=`echo $KEY | openssl enc -a -d -aes-128-cbc -kfile $PASSKEY 2> /dev/null`
  export PGPASSWORD="${PG_PASSWORD}"
}

function infoLog(){
  LDATE=$(date +[%m%d%Y%T])
  msg=$1
  logger -s ${LOG_FILE} ${msg}
  echo "$LDATE $msg" &>>${INSTALL_PATH}/${LOG_FILE}
}

function checkExitCode(){
  if [ $? -eq 0 ];  then
    infoLog "Step $1 finished successfully"
    return 0;
  fi
  infoLog "Step $1 failed. Exiting..."
  exit 1
}

function createRole(){
  infoLog "Creating role"
  roleExists=`PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c '\dg;' | grep ${DB_ROLE} | wc -l`
  if [ "$roleExists" -ge "1" ]; then
    infoLog "$DB_ROLE Role already exists – no further action required"
    return 0;
  else
    infoLog "Role $DB_ROLE doesnt exist. Creating..."
    2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c '\set ON_ERROR_STOP on'
    2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c \"CREATE ROLE $DB_ROLE LOGIN PASSWORD '$DB_ROLE_PSW' SUPERUSER CREATEDB CREATEROLE REPLICATION VALID UNTIL 'infinity';\"
    2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c 'ALTER DATABASE $DB OWNER TO $DB_ROLE;'
    2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c '\set ON_ERROR_STOP off'
  fi
}

function applyJberetSchema() {
  infoLog "Applying scheme to $DB "

  isJberetSchemaAvailable
  if [ $? -eq 0 ];  then
    infoLog "schema for ${DB} already exists"
    return 0;
  fi

  if [ -f ${INSTALL_PATH}/$DDL_FILE ]; then
    2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -d${DB} -q -w -f ${INSTALL_PATH}/$DDL_FILE
    checkExitCode "applyJberetSchema"
  else
    infoLog "${INSTALL_PATH}/$DDL_FILE is missing!"
    exit 1
  fi
}

function isJberetSchemaAvailable(){
SCHEMA_RESULT=$(PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -d ${DB} -U${PG_USER} -h $PG_HOSTNAME -c "select exists( select true where ( select count(*) from information_schema.tables where table_schema='public' and table_name in( 'partition_execution', 'step_execution', 'job_execution', 'job_instance'))=4 );" |  head -3 | tail -1 | sed 's/ //g')
    if [ $SCHEMA_RESULT == "t" ] ; then
       return 0;
    else
       return 1;
    fi
}

function logRotate() {
  if [ -f ${INSTALL_PATH}/${LOG_FILE} ]; then
    LDATE=$(date +[%m%d%Y%T])
    mv ${INSTALL_PATH}/${LOG_FILE} ${INSTALL_PATH}/${LOG_FILE}.${LDATE}
    touch  ${INSTALL_PATH}/${LOG_FILE}
    chmod a+w ${INSTALL_PATH}/${LOG_FILE}
  else
    touch  ${INSTALL_PATH}/${LOG_FILE}
    chmod a+w ${INSTALL_PATH}/${LOG_FILE}
  fi
}

#function serviceCheck(){
#  hostname=$(hostname)
#  is_running=$(service ${PG_LSB_1} status | grep -i "running" | wc -l 2>${INSTALL_PATH}/${LOG_FILE})
#  if [[ ${is_running} == 0 ]]; then
#    infoLog "Postgresql is not running on ${hostname} we cannot install ${DB} Objects at this time"
#    exit 1
#  else
#    infoLog "Postgresql is running on ${hostname} , we can now deploy ${DB} objects!"
#  fi
#}

function isDbCreated() {
  dbExists=$($PG_CLIENT -U postgres -h $PG_HOSTNAME PGPASSWORD=$PG_PASSWORD -c '\l' | grep ${DB_ROLE})
  if [ -z "$dbExists" ]; then
    return 1;# DB not present
  else
    return 0;# DB resent
  fi
}

function waitForDbCreation(){
  infoLog  "Database Validation for $DB"
  if [ ! isDbCreated ]; then
    infoLog "There is currently no $DB on this server, try to create and wait for ${PG_SLEEP_INT} seconds!!! "
    2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c \"createdb configds;\"
    for (( retry=0; retry < ${PG_NUM_TRIES}; retry++ )); do
      if [ ! isDbCreated ]; then
        infoLog "Database $DB now present. Can now Continue..."
        break
      fi
      sleep ${PG_SLEEP_INT}
    done
  fi
}

function changeSchemaOwnership() {
  roleExists=`PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -d${DB} -c '\dt;' | grep ${DB_ROLE} | wc -l`
  if [ "$roleExists" -eq "4" ]; then
     infoLog "Schema ownership is already $DB_ROLE in ${DB}"
     return 0;
  else
      infoLog "Changing schema ownership to $DB_ROLE in ${DB}"

      if [ -f ${INSTALL_PATH}/${OWNERSHIP_FILE} ]; then
        killAllExistingDBConnections

        2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -d${DB} -q -w -f ${INSTALL_PATH}/$OWNERSHIP_FILE

        checkExitCode "changeSchemaOwnership"
      else
        infoLog "${INSTALL_PATH}/$OWNERSHIP_FILE is missing!"
        exit 1
      fi
  fi
}

function killAllExistingDBConnections() {
  infoLog "About to terminate all existing connections to database ${DB}"

  2> ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -d${DB} -q -w -f ${INSTALL_PATH}/$KILL_EXISTING_CONNECTIONS_FILE
  infoLog "Terminated all existing connections to database ${DB}"
}

function updateRole(){
  infoLog "Updating role"
  roleExists=`PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c '\dg;' | grep ${DB_ROLE} | grep -i SuperUser | wc -l`
  if [ "$roleExists" -eq "0" ]; then
    infoLog "${DB_ROLE} is not a Superuser – no further action required"
    return 0;
  else
     infoLog "Altering $DB_ROLE ..."
    ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c '\set ON_ERROR_STOP on'
    ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c \"ALTER ROLE $DB_ROLE LOGIN PASSWORD '$DB_ROLE_PSW' NOSUPERUSER NOCREATEDB NOCREATEROLE REPLICATION VALID UNTIL 'infinity';\"
    ${INSTALL_PATH}/${LOG_FILE} PGPASSWORD=$PG_PASSWORD ${PG_ROOT}/psql -U${PG_USER} -h $PG_HOSTNAME -c '\set ON_ERROR_STOP off'
    return 0;
  fi
}


#*Main*
fetchpassword
logRotate
#serviceCheck
waitForDbCreation
createRole
applyJberetSchema
changeSchemaOwnership
updateRole

