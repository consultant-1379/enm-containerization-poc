#!/bin/sh
#
# chkconfig: 345 79 29
# description: Responsible for start & stop of JBosss
# processname: jboss
#
### BEGIN INIT INFO
# Provides: jboss
# Required-Start: $remote_fs $network $syslog
# Required-Stop: $remote_fs $network $syslog
# Should-Stop: sshd
# Default-Start: 3 4 5
# Default-Stop: 0 6
# Short-Description: start and stop JBoss
# Description: JBoss application server. The
#   bedrock of ENM. The init.d script is LSB
#   and OCF compliant.
### END INIT INFO

# Source function library.
. /etc/init.d/functions

# Load Java configuration.
[ -r /etc/java/java.conf ] && . /etc/java/java.conf
export JAVA_HOME

# Source jboss logger methods
. /ericsson/3pp/jboss/bin/jbosslogger

command=$1
export command

_MV='/bin/mv -f'

_CAT=/bin/cat

_CHOWN=/bin/chown

_CHMOD=/bin/chmod

_MKDIR=/bin/mkdir

_TOUCH=/bin/touch

_RM=/bin/rm

_GREP=/bin/grep

_SED=/bin/sed

_CP=/bin/cp

_AWK=/bin/awk

_MKDIR=/bin/mkdir

_TAR=/bin/tar

WAIT_FILE=/tmp/sfs_wait
export WAIT_FILE

JVM_CACERTS_STORE=/usr/java/default/jre/lib/security/cacerts
export JVM_CACERTS_STORE

JBOSS_USER=jboss_user
export JBOSS_USER

JBOSS_GROUP=jboss
export JBOSS_GROUP

JBOSS_HOME=/ericsson/3pp/jboss
export JBOSS_HOME

JBOSS_MODULES="$JBOSS_HOME/modules/system/layers/base"
export JBOSS_MODULES

JBOSS_CONSOLE_LOG=$JBOSS_HOME/standalone/log/console.log
export JBOSS_CONSOLE_LOG

JBOSS_SERVER_LOG=$JBOSS_HOME/standalone/log/server.log
export JBOSS_SERVER_LOG

JBOSS_MESSAGING_DATA_DIRECTORY=/ericsson/jms/data
export JBOSS_MESSAGING_DATA_DIRECTORY

JBOSS_AS_CONFIG_SCRIPT="$JBOSS_HOME/bin/configure_jboss_as.sh"
export JBOSS_AS_CONFIG_SCRIPT

if [ -z "$STARTUP_WAIT" ]; then
    STARTUP_WAIT=1800
fi
export STARTUP_WAIT

if [ -z "$DATA_SHARE_DIR" ]; then
    DATA_SHARE_DIR=/ericsson/tor/data
fi
export DATA_SHARE_DIR

if [ -z "$GLOBAL_CONFIG" ]; then
    GLOBAL_CONFIG="$DATA_SHARE_DIR/global.properties"
fi
export GLOBAL_CONFIG

# Load JBoss AS init.d configuration.
if [ -z "$JBOSS_CONF" ]; then
    [ -r "$JBOSS_AS_CONFIG_SCRIPT" ] && . "${JBOSS_AS_CONFIG_SCRIPT}"
fi
export JBOSS_CONF

# SOURCE_ORIG_JBOSS_CONF, this must happen before JBOSS_CONF
[ -n "$SOURCE_ORIG_JBOSS_CONF" ] && . "${SOURCE_ORIG_JBOSS_CONF}"

[ -r "$JBOSS_CONF" ] && . "${JBOSS_CONF}"

export USE_DEFAULT_WELCOME_ROOT


if [ -z "$MALLOC_ARENA_MAX" ]; then
    MALLOC_ARENA_MAX=4
fi
export MALLOC_ARENA_MAX

# Set defaults.

if [ -z "$DEPLOYABLE_ENTITIES_DIR" ]; then
    DEPLOYABLE_ENTITIES_DIR="/opt/ericsson"
fi

if [ -z "$EXT_MODULES" ]; then
   EXT_MODULES="/opt/ericsson/jboss/modules"
fi
export EXT_MODULES

if [ -z "$JBOSS_PIDFILE" ]; then
  JBOSS_PIDFILE=/var/run/jboss/jboss.pid
fi
export JBOSS_PIDFILE

if [ -z "$JBOSS_LOCKFILE" ]; then
  JBOSS_LOCKFILE=/var/lock/subsys/jboss
fi
export JBOSS_LOCKFILE



if [ -z "$STOP_WAIT" ]; then
    STOP_WAIT=30
fi

# Time wait to allow pre-stop tasks complete
if [ -z "$PRE_STOP_WAIT" ]; then
    PRE_STOP_WAIT=30
fi
export PRE_STOP_WAIT

if [ -z "$LOG_WAIT" ]; then
    LOG_WAIT=5
fi

if [ -z "$JBOSS_CONFIG" ]; then
    JBOSS_CONFIG=standalone.xml
fi
export JBOSS_CONFIG

if [ -z "$MGT_USER" ]; then
    MGT_USER=hqcluster
fi
export MGT_USER

if [ -z "$MGT_PASSWORD" ]; then
    MGT_PASSWORD=3ric550N
fi
export MGT_PASSWORD

if [ -z "$PRE_START_WITH_EXIT_DIR" ]; then
    PRE_START_WITH_EXIT_DIR="$JBOSS_HOME/bin/pre-start-with-exit"
fi

if [ -z "$PRE_START_DIR" ]; then
  PRE_START_DIR="$JBOSS_HOME/bin/pre-start"
fi

if [ -z "$PRE_DEPLOY_DIR" ]; then
    PRE_DEPLOY_DIR="$JBOSS_HOME/bin/pre-deploy"
fi

if [ -z "$PRE_STOP_DIR" ]; then
    PRE_STOP_DIR="$JBOSS_HOME/bin/pre-stop"
fi

if [ -z "$POST_START_DIR" ]; then
    POST_START_DIR="$JBOSS_HOME/bin/post-start"
fi

if [ -z "$POST_STOP_DIR" ]; then
    POST_STOP_DIR="$JBOSS_HOME/bin/post-stop"
fi

if [ -z "$JBOSS_SCRIPT" ]; then
    JBOSS_SCRIPT=$JBOSS_HOME/bin/standalone.sh
fi

if [ -z "$PIB_HOME" ]; then
    PIB_HOME="/opt/ericsson/PlatformIntegrationBridge/etc"
fi
export PIB_HOME

#List of DE(s) that do not participate in sdk-healthcheck or sdk-upgrade
if [ -z "$EXCLUDED_DES" ]; then
    EXCLUDED_DES="handler|wfs-camunda|mediation-router"
fi

if [ -z "$MODEL_DIR" ]; then
  MODEL_DIR="/etc/opt/ericsson/ERICmodeldeployment"
fi

if [ -z "$MODEL_REPO" ]; then
  MODEL_REPO="$MODEL_DIR/data/repo/modelrepo.xml"
fi
export MODEL_REPO

if [ -z "$MOD_CLUSTER_PORT" ]; then
    MOD_CLUSTER_PORT="8666"
fi
export MOD_CLUSTER_PORT

if [ -z "$ROOTCACERT_FILE" ]; then
    ROOTCACERT_FILE="$DATA_SHARE_DIR/certificates/rootCA.pem"
fi
export ROOTCACERT_FILE

if [ -z "$MODEL_DIR" ]; then
  MODEL_DIR="/etc/opt/ericsson/ERICmodeldeployment"
fi

if [ -z "$MODEL_REPO" ]; then
  MODEL_REPO="$MODEL_DIR/data/repo/modelrepo.xml"
fi

if [ -z "$PERM_GEN" ]; then
  PERM_GEN=512
fi
export PERM_GEN

if [ -z "$JMS_SERVER_RUNNING" ]; then
    JMS_SERVER_RUNNING="$DATA_SHARE_DIR/jmsserver.running"
fi
export JMS_SERVER_RUNNING

TEMP_LOCATION="$JBOSS_HOME/standalone/data/dps-jpa-ears"
DPS_JPA_UPGRADE_LOCK_FILE="$TEMP_LOCATION/dps_jpa_upgrade.running"
export DPS_JPA_UPGRADE_LOCK_FILE

DPS_NEW_JPA_DEPLOYING_STATUS_LOCK_FILE="$TEMP_LOCATION/dps_new_jpa_deploy_status.isdeploying"
export DPS_NEW_JPA_DEPLOYING_STATUS_LOCK_FILE

DPS_OLD_JPA_UNDEPLOY_STATUS_FILE="$TEMP_LOCATION/dps_old_jpa_undeploy_status.isundeploying"
export DPS_OLD_JPA_UNDEPLOY_STATUS_FILE

SHUTDOWN_NOTIF_SCRIPT="$JBOSS_HOME/bin/pre-stop/shutdown_notification.py"

EXTRA_CONFIG=$(cd $(dirname $0) ; pwd)/local.conf
[[ -f "${EXTRA_CONFIG}" ]] && . ${EXTRA_CONFIG}

if [ -z ${ENVIRONMENT_TYPE+x} ]; then
    ENVIRONMENT_TYPE="PRODUCTION"
fi
export ENVIRONMENT_TYPE

prog='jboss-as'

CMD_PREFIX=''

if [ ! -z "$JBOSS_USER" ]; then
  if [ -r /etc/rc.d/init.d/functions ]; then
    CMD_PREFIX="daemon --user $JBOSS_USER"
  else
    CMD_PREFIX="su - $JBOSS_USER -c"
  fi
fi

if [ -z "$STANDALONE_CONF" ]; then
      STANDALONE_CONF="$JBOSS_HOME/bin/standalone.conf"
fi


if [ "$ENVIRONMENT_TYPE" == "PRODUCTION" ]; then

    retCode=$("$JBOSS_HOME/bin/check_service_availability.sh")
    if [ "$retCode" != "0" ]; then
        warn "$prog failed to start, required services not available."
        failure
        echo
        exit 1
    fi
fi

[ -r "$STANDALONE_CONF" ] && . "${STANDALONE_CONF}"

if [ -z "$DPS_PERSISTENCE_PROVIDER" ]; then
   DPS_PERSISTENCE_PROVIDER="${GLOBAL_PROPERTIES_ARRAY[dps_persistence_provider]}"
fi

export DPS_PERSISTENCE_PROVIDER

if [ -z "$NEO4J_CLUSTER" ]; then
    NEO4J_CLUSTER="${GLOBAL_PROPERTIES_ARRAY[neo4j_cluster]}"
fi

export NEO4J_CLUSTER



export JB_MANAGEMENT
export JB_INTERNAL
export JB_PUBLIC
export THIS_HOST
export DEFAULT_IP
export DEFAULT_IF
export DEFAULT_MEM

UI_PRES_SERVER=${GLOBAL_PROPERTIES_ARRAY[UI_PRES_SERVER]}
export UI_PRES_SERVER

if [ -z "$PIB_ADDRESS" ]; then
    PIB_ADDRESS="$JB_INTERNAL:8080"
fi

export PIB_ADDRESS

if [ -z "$IS_CLOUD_DEPLOYMENT" ]; then
    IS_CLOUD_DEPLOYMENT="${GLOBAL_PROPERTIES_ARRAY[DDC_ON_CLOUD]}"
fi

export IS_CLOUD_DEPLOYMENT

if [ -z "$JGROUPS_STACK" ]; then
    JGROUPS_STACK="${GLOBAL_PROPERTIES_ARRAY[jgroups_protocol_stack]}"
    export JGROUPS_STACK
fi

TIMEOUT_FLAG=false

export JGROUPS_STACK

#######################################
# Action :
#   __set_jboss_transactions_identifier :
# Globals:
#   JB_INTERNAL
#   ADDTIONAL_JAVA_OPTS
# Arguments:
# Returns:
#
#######################################
__set_jboss_transactions_identifier () {
  JBOSS_TRANSACTION_ID=$(/bin/sed 's/\./_/g' <<< $JB_INTERNAL)
  JAVA_OPTS="$JAVA_OPTS -Djboss.transaction.id=${JBOSS_TRANSACTION_ID}"
}

#######################################
# Action :
#   __preStart
#   Performs any configuration needed
#   before starting the JBoss AS.
# Globals:
#   PRE_START_DIR
#   PRE_START_WITH_EXIT_DIR
#   JBOSS_HOME
#   JBOSS_USER
#   JBOSS_GROUP
#   EXT_MODULES
# Arguments:
#   None
# Returns:
#
#######################################
__preStart() {

  if [ -d ${DEPLOYABLE_ENTITIES_DIR} ];
  then
    #Find any EAR/WAR/RAR in deployments directory and copy to deployments folder
    info "EAR/WAR/RAR available before copying to deployments folder"
    _listDEs "$DEPLOYABLE_ENTITIES_DIR"
    find ${DEPLOYABLE_ENTITIES_DIR} -type f -regex ".*[\.[erw]ar" -exec cp {} ${JBOSS_HOME}/standalone/deployments/ \;
  fi

  #Delete any file that is not an EAR/WAR/RAR in the deployment directory
  find $JBOSS_HOME/standalone/deployments -type f -not -regex ".*[\.[erw]ar" -delete

  #Delete dps-jpa template ear
  $_RM -f $JBOSS_HOME/standalone/deployments/dps-jpa-ear-*-*.ear

  if [ -f "$DPS_JPA_UPGRADE_LOCK_FILE" ]; then
      $_RM -f "$DPS_JPA_UPGRADE_LOCK_FILE"
  fi

  if [ -f "$DPS_OLD_JPA_UNDEPLOY_STATUS_FILE" ]; then
      $_RM -f "$DPS_OLD_JPA_UNDEPLOY_STATUS_FILE"
  fi


  info "Run pre-start-with-exit scripts"
  __run_scripts_in_directory_with_exit_status "$PRE_START_WITH_EXIT_DIR"

  retCode=$?
  if [ "$retCode" -ne 0 ]; then
      warn "$prog failed to start, failed during pre start with exit script execution."
      return 1
  fi

  info "Run pre-start scripts"
  __run_scripts_in_directory $PRE_START_DIR false


  if [ "$ENVIRONMENT_TYPE" == "PRODUCTION" ]; then

    ADDTIONAL_JAVA_OPTS=$("$JBOSS_HOME/bin/configure_production_env.sh")
    if [ -z "$ADDTIONAL_JAVA_OPTS" ]; then
        warn "$prog failed to start, failed to configure production environment."
        return 1
    else
        JAVA_OPTS="$JAVA_OPTS $ADDTIONAL_JAVA_OPTS"
    fi
  fi

  # change permissions on all DE's so we can overwrite DE with ejb-client.xml
  $_CHMOD -R 755 $JBOSS_HOME || true
  $_CHOWN -R $JBOSS_USER:$JBOSS_GROUP $JBOSS_HOME || true

  # remove execution permissions from all README files
  find $JBOSS_HOME/bin -name README| xargs $_CHMOD -x+X



  # change permission on all modules so that they can be run by JBOSS_USER
  if [ -d ${EXT_MODULES} ];
  then
      $_CHOWN -R $JBOSS_USER:$JBOSS_GROUP $EXT_MODULES || true
  fi

  __set_jboss_transactions_identifier


  # Now we have full list of JAVA_OPTS
  # export for use in standalone.sh
  export JAVA_OPTS

  # Dont want to start deployment of DE(s) until all subsystems in JBoss are started
    find $JBOSS_HOME/standalone/deployments -type f -regex ".*[\.[erw]ar" -exec mv {} ${JBOSS_HOME}/standalone/tmp/deployments/ \;
    info "EAR/WAR/RAR available in temporary deployments folder"
    _listDEs "$JBOSS_HOME/standalone/tmp/deployments"
 }

#######################################
# Action :
#   __preDeploy
#   Performs any configuration needed
#   after the JBoss AS is started, but
#   before deploying any DE.
# Globals:
#   PRE_DEPLOY_DIR
# Arguments:
#   None
# Returns:
#
#######################################
__preDeploy() {

  info "Run pre-deploy scripts"
  __run_scripts_in_directory_with_exit_status $PRE_DEPLOY_DIR
  return $?

}

#######################################
# Action :
#   __checkJBossServerRunning :
# Checks whether JBoss is running and ready to take deployments or not
# Returns:
#         0 if jboss is in running state
#         1 if jboss process is running but not yet in running state
#         2 if jboss-as doesn't respond other than timeout issues
#         28 if jboss-as doesn't respond in time
#
#######################################
__checkJBossServerRunning() {
  TIMEOUT_FLAG=false
  START_TIME=$(($(date +%s%N)/1000000))
  SERVER_STATE=$(curl -m 16 -s --digest -L -D - http://$JB_MANAGEMENT:9990/management --header "Content-Type: application/json" -d '{"operation":"read-attribute","name":"server-state","json.pretty":1}'  -u $MGT_USER:$MGT_PASSWORD )
  SERVER_STATE_EXIT_CODE=$?
  END_TIME=$(($(date +%s%N)/1000000))
  TIMEDIFF=$(($END_TIME - $START_TIME))
  info "Jboss CURL command took $TIMEDIFF milliseconds"


  if [ $SERVER_STATE_EXIT_CODE == 0 ]
    then
    echo $SERVER_STATE| grep "\"result\" : \"running\"" >> /dev/null
      if [ $? == 0 ] ; then
         return 0
      else
         info "jboss-as is starting"
         return 1
      fi
    elif [ $SERVER_STATE_EXIT_CODE == 28 ] ; then
      _takeJbossThreadDump
      # not all the VMs has JBoss gc.log enabled, we only dump the GC if the log exists
      if ls /ericsson/3pp/jboss/standalone/log/server-gc.log.* > /dev/null 2>&1; then
          _takeJbossGcDump
      fi
      TIMEOUT_FLAG=true
      info "jboss-as status check code : $SERVER_STATE_EXIT_CODE"
      return 28
    else
      info "jboss-as status check code : $SERVER_STATE_EXIT_CODE"
      return 2
    fi

}


#######################################
# Action :
#   start
#   Starts the JBoss AS
# Globals:
#   JBOSS_PIDFILE
#   JBOSS_CONSOLE_LOG
#   JBOSS_SERVER_LOG
#   JBOSS_USER
#   LAUNCH_JBOSS_IN_BACKGROUND
#   JBOSS_SCRIPT
#   JBOSS_CONSOLE_LOG
#   STARTUP_WAIT
#   POST_START_DIR
#   JBOSS_LOCKFILE
# Arguments:
#   None
# Returns:
#   0 Resource started or already running
#   1 Resource failed to start
#######################################
_start() {

  info "Starting $prog: "
  if [ -f $JBOSS_PIDFILE ]; then
    read ppid < $JBOSS_PIDFILE
    if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '1' ]; then
      info "$prog is already running"
      $_RM -f $WAIT_FILE
      success
      echo
      return 0
    else
      rm -f $JBOSS_PIDFILE
    fi
  fi

  # Don't run __preStart if jboss already running.
  __preStart
  retCode=$?
  if [ $retCode -ne 0 ]; then
      $_RM -f $WAIT_FILE
      failure
      echo
      return 1
  fi

  $_MKDIR -p $(dirname $JBOSS_CONSOLE_LOG)
  $_CAT /dev/null > $JBOSS_CONSOLE_LOG


  $_MKDIR -p $(dirname $JBOSS_PIDFILE)
  $_CHOWN $JBOSS_USER $(dirname $JBOSS_PIDFILE) || true

  if [ ! -f $JBOSS_SERVER_LOG ]; then
    $_MKDIR -p $(dirname $JBOSS_SERVER_LOG)
    $_CHOWN $JBOSS_USER:$JBOSS $(dirname $JBOSS_SERVER_LOG) || true
  fi

  if [ -f $JBOSS_LOCKFILE ]; then
    warn "$prog failed to start, lock file exists"
        $_RM -f $WAIT_FILE
    failure
    echo
    return 1
  fi
  info "Executing daemon with parameters Jboss user = $JBOSS_USER , JBOSS_PIDFILE = $JBOSS_PIDFILE "
  daemon --user $JBOSS_USER LAUNCH_JBOSS_IN_BACKGROUND=1 JBOSS_PIDFILE=$JBOSS_PIDFILE $JBOSS_SCRIPT -c $JBOSS_CONFIG 2>&1 > $JBOSS_CONSOLE_LOG 
      #info "Executing su with parameters Jboss user = $JBOSS_USER , JBOSS_PIDFILE = $JBOSS_PIDFILE "
      #su - $JBOSS_USER -c "LAUNCH_JBOSS_IN_BACKGROUND=1 JBOSS_PIDFILE=$JBOSS_PIDFILE $JBOSS_SCRIPT -c $JBOSS_CONFIG" 2>&1 > $JBOSS_CONSOLE_LOG &
}

#######################################
# Action :
#   __run_scripts_in_directory
#   Run all scripts in specified
#   directory
# Globals:
#   None
# Arguments:
#   1 - Absolute path to the directory
#   containing scripts to be run.
#   2 - Run as background process, true/false
# Returns:
#
#######################################
__run_scripts_in_directory() {
    for SCRIPT in $1/*
        do
            if [ -f "$SCRIPT" -a -x "$SCRIPT" ]
            then
                if [ "$2" = true ] ; then
                    info "JBoss execute script as background process : $SCRIPT"
                    $SCRIPT > /dev/null 2>&1 &
                else
                    info "JBoss execute script : $SCRIPT"
                    $SCRIPT > /dev/null 2>&1
                fi
            fi
        done
}

#######################################
# Action :
#   __run_scripts_in_directory_with_exit_status
#   Run all scripts in specified
#   directory. Return 1 in case of
#   any script failure.
# Globals:
#   None
# Arguments:
#   1 - Absolute path to the directory
#   containing scripts to be run.
# Returns:
#   0 - if all scripts in the directory are
#   successfully executed
#   1 - in case of any script failure
#######################################
__run_scripts_in_directory_with_exit_status() {
    for SCRIPT in $1/*
    do
        if [ -f "$SCRIPT" -a -x "$SCRIPT" ]
        then
            info "JBoss execute script : $SCRIPT"
            $SCRIPT > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                error "Script failing : $SCRIPT"
                return 1
            fi
        fi
    done
    return 0
}

#######################################
# Action :
#   __run_scripts_in_directory_specified_script_at_last
#   Run all scripts in specified directory and specified
#   one is executed at last.
# Globals:
#   None
# Arguments:
#   1 - Absolute path to the directory
#   containing scripts to be run.
#   2 - Run as background process, true/false
#   3 - The script to be executed at last
# Returns:
#
#######################################
__run_scripts_in_directory_specified_script_at_last() {
    for SCRIPT in $1/*
        do
            if [ "$SCRIPT" == "$3" ]; then
                continue
            fi

            if [ -f "$SCRIPT" -a -x "$SCRIPT" ]
            then
                if [ "$2" = true ] ; then
                    info "JBoss execute script as background process : $SCRIPT"
                    $SCRIPT > /dev/null 2>&1 &
                else
                    info "JBoss execute script : $SCRIPT"
                    $SCRIPT > /dev/null 2>&1
                fi
            fi
        done

    if [ -f "$3" ]; then
        info "JBoss execute script : $3"
        $3 > /dev/null 2>&1
    fi

}

#######################################
# Action :
#   stop
#   Issue shutdown notification to all
#   services running in the VM before
#   stopping JBoss.
# Globals:
#   MGT_USER
#   MGT_PASSWORD
#   JB_MGT
# Arguments:
#   None
# Returns:
#
#######################################
stop() {

    info $"Stopping $prog: "
    count=0;

    if [ -f $JBOSS_PIDFILE ]; then

        __findServiceIDS

        info "Run pre-stop scripts"
        __run_scripts_in_directory_specified_script_at_last "$PRE_STOP_DIR" false "$SHUTDOWN_NOTIF_SCRIPT"

        read kpid < $JBOSS_PIDFILE
        let kwait=$STOP_WAIT

        # Try issuing SIGTERM
        kill -15 "$kpid"
        until [ `ps --pid $kpid 2> /dev/null | grep -c $kpid 2> /dev/null` -eq '0' ] || [ $count -gt $kwait ]
        do
          sleep 1
          let count=$count+1;
        done

        if [ $count -gt $kwait ]; then
        kill -9 "$kpid"
        fi
    fi

    rm -f $JBOSS_PIDFILE

    if [ -f $JBOSS_LOCKFILE ]; then
            $_RM -f $JBOSS_LOCKFILE
    fi

  if [ -f $DPS_JPA_UPGRADE_LOCK_FILE ]; then
      $_RM -f $DPS_JPA_UPGRADE_LOCK_FILE
  fi

  if [ -f $DPS_OLD_JPA_UNDEPLOY_STATUS_FILE ]; then
        $_RM -f $DPS_OLD_JPA_UNDEPLOY_STATUS_FILE
    fi

  if [ -f "$WAIT_FILE" ]; then
      $_RM -f $WAIT_FILE
  fi

    info "Run post-stop scripts"
    __run_scripts_in_directory $POST_STOP_DIR true

    success
    echo
}



#######################################
# Action :
#   __findServiceIDS
# Globals:
#   EXCLUDED_DES
# Arguments:
#   None
# Returns:
#   Exports white space separated, list of
#   service identifiers to issue shutdown
#   notifications to.
#######################################
__findServiceIDS() {
    SERVICE_ID_LIST=$(find $JBOSS_HOME/standalone/deployments -type f -not -path "*no_sdk_checks*" -regex ".*[\.[ew]ar" | grep -oP "([^/]*(?=(-ear|-war)))" | egrep -iv $EXCLUDED_DES)
    export SERVICE_ID_LIST
}


#######################################
# Action :
#   status
# Globals:
#   MGT_USER
#   MGT_PASSWORD
#   JB_MANAGEMENT
#   JBOSS_PIDFILE
#   JBOSS_LOCKFILE
# Arguments:
#   None
# Returns:
#   0 Resource is started, DE(s) deployed
#   1 Resource is in failed state, pid file exists
#   2 Resource is in failed state, lock file exists
#   3 Resource is stopped or starting because of jboss-as is not responding other than time out or failure reasons
#######################################
status() {

  __checkStarting
  rc=$?
  if [ $rc -ne 0 ] ; then
    return $rc
  fi
  #read JB_MANAGEMENT again just in case global.properties not accessible
  if [ -z "$JB_MANAGEMENT" ]; then
    read ppid < $JBOSS_PIDFILE
    JB_MANAGEMENT=$($_PS -f --pid $ppid 2> /dev/null | $_GREP $ppid 2> /dev/null | $_SED -e 's/.*jboss.bind.address.management=\(\S*\).*/\1/g' 2> /dev/null)
  fi
   __checkJBossServerRunning
  checkjbossrc=$?
  if [ "$checkjbossrc" -eq 0 ]; then
    echo "$prog is running"
    return 0
  elif [ "$checkjbossrc" -eq 28 ]; then

    _check_file "$DPS_JPA_UPGRADE_LOCK_FILE"
    lockrc=$?
    if [ "$lockrc" -eq 0 ]; then
      info "jboss-as status check timeout - DPS Deployment in progress"
      return 0
    else
      warn "jboss-as healthcheck curl command timed out, check threaddump at /ericsson/enm/dumps/threadDumps"
      return 1
    fi
  else
    _check_file "$JBOSS_PIDFILE"
    pidfilerc=$?
    if [ "$pidfilerc" -eq 0 ]; then
      read ppid < $JBOSS_PIDFILE
      if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '0' ]; then
        error "$prog dead but pid file exists"
        return 1
      else
        echo "$prog is running"
        return 0
      fi
    else
      _check_file "$JBOSS_LOCKFILE"
      lockfilerc=$?
      if [ "$lockfilerc" -eq 0 ]; then
        error "$prog dead but lock file exists"
        return 2
      fi
    fi
  fi
    error "$prog is not running"
    return 1
}
#######################################
# Action :
#   _check_file
#   Checks and wait 2sec for file on SFS
# Arguments:
#   FileName
# Returns:
#  0 if file reachable
#  1 if file not reachable and timeout
#######################################

_check_file(){
    timeout 2 ls "$1" > /dev/null 2>&1
    filelsrc=$?
    if [ "$filelsrc" -eq 0 ]; then
      return 0
    else
      return 1
    fi
}
#######################################
# Action :
#   check JBoss is starting
# Globals:
#   JBOSS_HOME
#   JBOSS_PIDFILE
#   STARTUP_WAIT
# Arguments:
#   None
# Returns:
#   0 started
#   1 failed
#   3 stopped or still starting
#######################################
__checkStarting() {

# Handle DPA upgrade case, if all DEs deployed, and DPS upgrade starts,
# we could have latest JPA war in isdeploying status or old JPA war in undeploying status
# this case, JBoss is NOT STARTING
# Also we can have a window where the deployment or undeployment is not yet started
# as the jboss scanner has a delay of 5 seconds

if [ -f "$DPS_JPA_UPGRADE_LOCK_FILE" ]; then
   # DPS JPA upgrade started. need to factor deploying & undeploying status
   deployingCount=$(find $JBOSS_HOME/standalone/deployments -type f -iname '*.*deploying' | wc -l)

   if [ -f "$DPS_NEW_JPA_DEPLOYING_STATUS_LOCK_FILE" ]; then
       if [ "$deployingCount" -eq 1 ]; then
           info "Upgrade of DPS JPA EAR in progress, Deploying new DE."
       else
           info "Upgrade of DPS JPA EAR in progress, new DE deployment not yet started."
       fi
       return 0
   fi

   if [ -f "$DPS_OLD_JPA_UNDEPLOY_STATUS_FILE" ]; then
       if [ "$deployingCount" -eq 1 ]; then
           info "Upgrade of DPS JPA EAR in progress, Undeploying old DE."
       else
           info "Upgrade of DPS JPA EAR in progress, old DE un-deployment not yet started."
       fi
       return 0
   fi

   info "DPS JPA EAR Upgrade is still in progress."
   return 0
fi

numberDE=$(find $JBOSS_HOME/standalone/deployments -type f -iname '*.[e|w|r]ar' | wc -l)

#file name will end in either .deployed or .failed
numberDeployed=$(find $JBOSS_HOME/standalone/deployments -type f -iname '*.*ed' | wc -l)

if [ "$numberDE" -eq "$numberDeployed" ] ; then
    if [ "$numberDE" -eq 0 ]; then
    warn "No DEs available to be deployed."
    info "$prog Still starting"
        return 3
    fi
    return 0
fi
_check_file "$JBOSS_PIDFILE"
pidfile2rc=$?
if [ "$pidfile2rc" -eq 0 ]; then
    read ppid < "$JBOSS_PIDFILE"
    startTime=$(date -d "$(ps -p "$ppid" -o lstart | awk '{if(NR>1)print}')" '+%s')
    let uptime=$(date '+%s')-${startTime}
    if [ "${uptime}" -gt "$STARTUP_WAIT" ] ; then
      _check_file "$DPS_JPA_UPGRADE_LOCK_FILE"
      dpsuprc=$?
      if [ "$dpsuprc" -eq 1 ]; then
        # Startup time has elapsed and all DE(s) still not deployed so failed
        error "$prog Startup time has elapsed and all DE(s) still not deployed so failed"
        return 1
      else
        info "Upgrade of DPS JPA EAR still in progress."
        return 0
      fi
  else
      info "$prog Still starting"
      return 3
  fi
else
  error "$prog is not running"
fi
}

#######################################
# Action :
#   monitor
# Globals:
#   MGT_USER
#   MGT_PASSWORD
#   JB_MGT
# Arguments:
#   None
# Returns:
#   0 Resource is running
#   1 Resource is in failed state
#   7 Resource is stopped or still starting
#######################################
monitor() {

 # during dps upgrade on lcm server we will not attempt to contact jboss
 if [[ $HOSTNAME == *lcmserv ]] ; then
    _check_file "$DPS_JPA_UPGRADE_LOCK_FILE"
    lockrc=$?
    if [ "$lockrc" -eq 0 ]; then
      info "jboss-as status check timeout -DPS upgrade in progress on a lcmserv vm"
      return 0
    fi
 fi

 status
 statusrc=$?
 if [ $statusrc -eq 1 ] ; then
    return 1
 elif [ $statusrc -eq 2 ] ; then
    return 7
 elif [ $statusrc -eq 3 ] ; then
    return 7
 fi
#read JB_MANAGEMENT again just in case golbal.properties not accessible
 if [ -z "$JB_MANAGEMENT" ]; then
    read ppid < "$JBOSS_PIDFILE"
    JB_MANAGEMENT=$($_PS -f --pid $ppid 2> /dev/null | $_GREP $ppid 2> /dev/null | $_SED -e 's/.*jboss.bind.address.management=\(\S*\).*/\1/g' 2> /dev/null)
fi
# If status check has passed then Management interface is up and all DE(s) are deployed.
$JBOSS_HOME/bin/upgrade/upgrade_dps_jpa_ear.sh & >> /dev/null 2>&1
START_TIME=$(($(date +%s%N)/1000000))
output=$(curl -m 16 --digest -L -D - http://$JB_MANAGEMENT:9990/management --header 'Content-Type: application/json' -d '{"operation":"read-attribute","address":[{"deployment":"*"}],"name":"status","json.pretty":1}' -u $MGT_USER:$MGT_PASSWORD)
outputrc=$?
END_TIME=$(($(date +%s%N)/1000000))
TIMEDIFF=$(($END_TIME - $START_TIME))
info "Monitor CURL command took $TIMEDIFF milliseconds"
if [ "$outputrc" -eq 28 ]; then
    _check_file "$DPS_JPA_UPGRADE_LOCK_FILE"
    lockrc=$?
    if [ "$lockrc" -eq 0 ]; then
      info "jboss-as status check timeout -DPS upgrade in progress"
      return 0
    else
      warn "jboss-as healthcheck curl command timed out, check thread_dumps or gc_dumps (if enabled) at /ericsson/enm/dumps"
      if [ "$TIMEOUT_FLAG" = false ] ; then
          _takeJbossThreadDump
          # not all the VMs has JBoss gc.log enabled, we only dump the GC if the log exists
          if ls /ericsson/3pp/jboss/standalone/log/server-gc.log.* > /dev/null 2>&1; then
              _takeJbossGcDump
          fi
      fi
      return 1
    fi
fi

# Need to ensure we have all DE(s) in state OK not FAILED or STOPPED
failed=$(echo "$output" | egrep "FAILED|STOPPED" | wc -l)

if [ "$failed" -gt 0 ] ; then
  error "Found DE in FAILED/STOPPED state on $THIS_HOST"
  error "$output"
  echo "$prog has failed/stopped services"
  return 1
fi

totalDEs=$(find $JBOSS_HOME/standalone/deployments -type f -iname '*.[e|w|r]ar' | wc -l)
failed_undeployed_DEs=$(find $JBOSS_HOME/standalone/deployments \( -type f -iname '*.failed' -o -iname '*.undeployed' \) -a ! -iname "dps-jpa-ear-runtime*")
failed_undeployed_DEs_COUNT=`echo $failed_undeployed_DEs | wc -w`

if [ "$failed_undeployed_DEs_COUNT" -gt 0 ]; then
    # Need to log this as info in ES
    info "All Failed Undeployed DE list: $failed_undeployed_DEs"
    if [ "$totalDEs" -eq "$failed_undeployed_DEs_COUNT" ]; then
        error "All DEs in failed/undeployed state on $THIS_HOST"
    else
        if [ -f $DPS_OLD_JPA_UNDEPLOY_STATUS_FILE -a $failed_undeployed_DEs_COUNT -eq 1 ]; then
            ## it's our DPS OLD JPA. the .undeployed file isn't removed yet.
            ## We would return 0 zero here since new JPA should have been deployed anyway.
            info "Old DPS JPA EAR .undeployed file not removed yet."
            return 0
        else
            error "Found DE in failed/undeployed state on $THIS_HOST"
        fi
    fi
    return 1
fi

return 0

}

metadata_jboss()
{
    $_CAT <<END
<?xml version="1.0"?>
<!DOCTYPE resource-agent SYSTEM "ra-api-1.dtd">

<resource-agent name="jboss">
<version>1.0</version>

<longdesc lang="en">
Resource script for Jboss. It manages a Jboss instance as an HA resource.
</longdesc>
<shortdesc lang="en">Manages a JBoss application server instance</shortdesc>

</resource-agent>
END
    return 0
}

#Takes a thread dump of the jboss process and then logs the threaddump to
#/ericsson/enm/dumps/threadDumps in a compressed file
_takeJbossThreadDump()
{
      sharedThreadDumpDirectory="/ericsson/enm/dumps/thread_dumps"
      localThreadDumpDirectory="/ericsson/3pp/jboss/standalone/log/threadDumps"
      logrotateConfigFile="/ericsson/3pp/jboss/bin/logrotate_thread-dumps.conf"

      #Creates the shared directory if it is not there already
      $_MKDIR -p $sharedThreadDumpDirectory/$HOSTNAME

      #This ensures that if the vm is clean started that it does not overwrite the newest threaddumps
      if [ ! -d $localThreadDumpDirectory ]; then
          $_MKDIR -p $localThreadDumpDirectory
          $_CP -p $sharedThreadDumpDirectory/$HOSTNAME $localThreadDumpDirectory/
      fi

      #Take a thread dump of the jboss jvm
      THREAD_DUMP_FILE="/ericsson/3pp/jboss/standalone/log/thread_dump_"$HOSTNAME".dump"
      info "Timeout exceeded. Sending thread dump to $THREAD_DUMP_FILE"
      PID_NO=$($_AWK '{print $1}' "$JBOSS_PIDFILE")
      su jboss_user -c "/usr/java/default/bin/jcmd $PID_NO Thread.print" > "$THREAD_DUMP_FILE" 2>&1

      #rotate the logs and send a copy to the shared location
      /usr/sbin/logrotate -f "$logrotateConfigFile" &
}

# copies the JBoss garbage collection log (server-gc.log*) to the below shared storage
# /ericsson/enm/dumps/gcDumps
_takeJbossGcDump()
{
    sharedGcDumpDir="/ericsson/enm/dumps/gc_dumps"
    localGcDir="/ericsson/3pp/jboss/standalone/log"
    localGcDumpDir="${localGcDir}/gcDumps"
    logrotateConfigFile="/ericsson/3pp/jboss/bin/logrotate_gc-dumps.conf"

    # Creates the shared directory if it is not there already
    $_MKDIR -p $sharedGcDumpDir/$HOSTNAME

    # This ensures that if the vm is clean started that it does not overwrite the newest gc dumps
    # This could mean either a first time run or clean started
    if [[ ! -d $localGcDumpDir ]]; then
        # Creates the local gcDumps directory if it is not there already
        $_MKDIR -p $localGcDumpDir
        $_CP -p $sharedGcDumpDir/${HOSTNAME} $localGcDumpDir > /dev/null 2>&1
    fi

    info "Timeout exceeded. Sending GC logs to ${sharedGcDumpDir} directory"
    cd ${localGcDir}
    # here we will logrotate the tar ball file of the gc.log
    $_TAR -cf ${localGcDumpDir}/$HOSTNAME.server-gc.log.tar server-gc.log*
    cd -

    #rotate the logs and send a copy to the shared location
    /usr/sbin/logrotate -f "$logrotateConfigFile" &
}

# Lists all EAR/WAR/RAR DEs in the specified directory
_listDEs(){
  DIR=$1
  info "$(find $DIR -type f -regex ".*[\.[erw]ar" -exec ls {} \;)"
}

