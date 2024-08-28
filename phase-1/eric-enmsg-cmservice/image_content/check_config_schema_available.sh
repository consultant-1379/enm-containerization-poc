#!/bin/bash

##########################################################################
# COPYRIGHT Ericsson 2015
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##########################################################################


##########################################################################
#
#    PURPOSE: This script delays startup of jboss until
#                  postgres is available,
#                  the config role exists and
#                  the config schema has been created.
#
##########################################################################

#*Variables*
PG_ONLINE_MAX_RETRIES=60                # Postgres should already be online before this script is called
PG_ONLINE_RETRY_SLEEP_TIME=10           # Max wait/retry time will be 10 mins
PG_SCHEMA_MAX_RETRIES=10
PG_SCHEMA_RETRY_SLEEP_TIME=10
PG_CONN_AVAILABLE_AS_ROLE_MAX_RETRIES=20
PG_CONN_AVAILABLE_AS_ROLE_SLEEP_TIME=10

POSTGRES_SERVER_RUNNING="false"
POSTGRES_SCHEMA_AVAILABLE="false"
PG_CONN_AVAILABLE_AS_ROLE="false"

CAN_CONNECT_AS_ROLE=false;

DB_HOST=postgresql01
DB_PORT=5432
APP_USER_ROLE=config_admin
APP_USER_PWD=config_pass
DB=configds
PSQL=/usr/bin/psql

#######################################
# Action :
#   Log at INFO level
# Globals:
#   None
# Arguments:
#   Message string
# Returns:
#
#######################################
info() {

	logger -t CMCONFIG -p user.info "INFO ($prg): $@"
}

#######################################
# Action :
#   Log at ERROR level
# Globals:
#   None
# Arguments:
#   Message string
# Returns:
#
#######################################
error() {

	logger -s -t CMCONFIG  -p user.err "ERROR ($prg): $@"
}

#######################################
# Action :
# Sets POSTGRES_SERVER_RUNNING to true if postgres is responding
# on remote server postgresql01 on port 5432
#
# Globals :
#   POSTGRES_SERVER_RUNNING
#
# Arguments:
#   None
# Returns:
#
#######################################
__is_postgres_running(){
    $(echo > /dev/tcp/$DB_HOST/$DB_PORT) >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
        POSTGRES_SERVER_RUNNING=true
    else
        POSTGRES_SERVER_RUNNING=false
    fi
}

#######################################
# Action :
# Sets PG_CONN_AVAILABLE_AS_ROLE to true a connection can be made to postgres for the
# user $APP_USER_ROLE
#
# Globals :
#   POSTGRES_SERVER_RUNNING
#   APP_USER_ROLE
#   APP_USER_PWD
#   DB
#   DB_HOST
#   DB_PORT
#   POSTGRES_SCHEMA_AVAILABLE
#
# Arguments:
#   None
# Returns:
#
#######################################
__can_connect_to_postgres_with_role(){
    PGPASSWORD=${APP_USER_PWD} ${PSQL} -U ${APP_USER_ROLE} --host=${DB_HOST} -d ${DB} -p ${DB_PORT} -c "select true" >/dev/null
    if [ $? -eq 0 ] ; then
        PG_CONN_AVAILABLE_AS_ROLE=true
    else
        PG_CONN_AVAILABLE_AS_ROLE=false
    fi
}

#######################################
# Action :
# Sets POSTGRES_SCHEMA_AVAILABLE to true if the schema is available in the database
# on remote server $DB_HOST on port $DB_PORT for the $DB for the user $APP_USER_ROLE
#
# Globals :
#   POSTGRES_SERVER_RUNNING
#   APP_USER_ROLE
#   APP_USER_PWD
#   DB
#   DB_HOST
#   DB_PORT
#   POSTGRES_SCHEMA_AVAILABLE
#
# Arguments:
#   None
# Returns:
#
#######################################
__is_postgres_schema_created(){
    SCHEMA_RESULT=`PGPASSWORD=${APP_USER_PWD} ${PSQL} -U ${APP_USER_ROLE} --host=${DB_HOST} -d ${DB} -p ${DB_PORT} -c "select exists( select true where ( select count(*) from information_schema.tables where table_schema='public' and table_name in( 'partition_execution', 'step_execution', 'job_execution', 'job_instance'))=4 )" | head -3 | tail -1 | sed 's/ //g'`
    if [ $SCHEMA_RESULT == "t" ] ; then
        POSTGRES_SCHEMA_AVAILABLE=true
    else
        POSTGRES_SCHEMA_AVAILABLE=false
    fi
}

#######################################
# Action :
# Waits until postgres is reachable on remote db's server port
#
# Globals :
#   POSTGRES_SERVER_RUNNING
#   PG_ONLINE_MAX_RETRIES
#   PG_ONLINE_RETRY_SLEEP_TIME
# Arguments:
#   None
# Returns:
#
#######################################
__wait_until_postgres_available() {
	wait=0
	while [[ "$POSTGRES_SERVER_RUNNING" == "false" ]]
	do
		if [ $wait -gt $PG_ONLINE_MAX_RETRIES ]; then
			break
		fi

		__is_postgres_running
		if [[ "$POSTGRES_SERVER_RUNNING" == "false" ]]; then
			info "Postgres server not running - waiting"
			sleep $PG_ONLINE_RETRY_SLEEP_TIME
			let wait=$wait+1;
		fi
	done
	if [[ "$POSTGRES_SERVER_RUNNING" == "false" ]]; then
		error "Postgres server is not ready - timed out"
		exit 1
	fi
}

#######################################
# Action :
# Wait until connection to postgres as the application user/role is available or timeout
#
# Globals :
#   PG_CONN_AVAILABLE_AS_ROLE
#   PG_CONN_AVAILABLE_AS_ROLE_MAX_RETRIES
#   PG_CONN_AVAILABLE_AS_ROLE_SLEEP_TIME
# Arguments:
#   None
# Returns:
#
#######################################
__wait_until_connect_as_application_role() {
	wait=0
	while [[ "$PG_CONN_AVAILABLE_AS_ROLE" == "false" ]]
	do
		if [ $wait -gt $PG_CONN_AVAILABLE_AS_ROLE_MAX_RETRIES ]; then
			break
		fi

		__can_connect_to_postgres_with_role
		if [[ "$PG_CONN_AVAILABLE_AS_ROLE" == "false" ]]; then
			info "Postgres connection as role not available - waiting"
			sleep $PG_CONN_AVAILABLE_AS_ROLE_SLEEP_TIME
			let wait=$wait+1;
		fi
	done
	if [[ "$PG_CONN_AVAILABLE_AS_ROLE" == "false" ]]; then
		error "Postgres connection with application role is not available - timed out"
		exit 1
	fi
}

#######################################
# Action :
# Waits until postgres schema is available/created on remote db's server port
#
# Globals :
#   POSTGRES_SCHEMA_AVAILABLE
#   PG_SCHEMA_MAX_RETRIES
#   PG_SCHEMA_RETRY_SLEEP_TIME
# Arguments:
#   None
# Returns:
#
#######################################
__wait_until_schema_available() {
	wait=0
	while [[ "$POSTGRES_SCHEMA_AVAILABLE" == "false" ]]
	do
		if [ $wait -gt $PG_SCHEMA_MAX_RETRIES ]; then
			break
		fi

		__is_postgres_schema_created
		if [[ "$POSTGRES_SCHEMA_AVAILABLE" == "false" ]]; then
			info "Postgres schema for cmconfig not available - waiting"
			sleep $PG_SCHEMA_RETRY_SLEEP_TIME
			let wait=$wait+1;
		fi
	done
	if [[ "$POSTGRES_SCHEMA_AVAILABLE" == "false" ]]; then
		error "Postgres schema for cmconfig is not available - timed out"
		exit 1
	else
		info "Schema found in postgres for application - cmconfig"
	fi
}

__wait_until_postgres_available
__wait_until_connect_as_application_role
__wait_until_schema_available
