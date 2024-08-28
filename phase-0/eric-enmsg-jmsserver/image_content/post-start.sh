#!/bin/bash

_CAT=/bin/cat
_RM=/bin/rm
_EGREP=/bin/egrep
_GREP=/bin/grep
_SED=/bin/sed
_PS=/bin/ps

WAIT_FILE=/tmp/sfs_wait
STARTUP_WAIT=1800
JBOSS_HOME=/ericsson/3pp/jboss
POST_START_DIR="$JBOSS_HOME/bin/post-start"
JBOSS_PIDFILE=/var/run/jboss/jboss.pid
JBOSS_LOCKFILE=/var/lock/subsys/jboss
JBOSS_MESSAGING_DATA_DIRECTORY=/ericsson/jms/data
JMS_LOG_DIR=/ericsson/jms/log
HQ_FATAL_EXCEPTION_LOG=$JMS_LOG_DIR/hqfatalexception.log
JOURNAL_DIRECTORY="$JBOSS_MESSAGING_DATA_DIRECTORY/journal/"
JOURNALS_MOVING_LOCK_FILE="$JBOSS_MESSAGING_DATA_DIRECTORY/journals.moving"
JOURNAL_SCRIPT="$JBOSS_HOME/bin/journalStatus.sh"

MGT_PASSWORD=3ric550N
MGT_USER=hqcluster

. $JBOSS_HOME/bin/jmslogger

launched=false
started=false
count=10

poststart() {

  while [ "$started" == "false" ]
  do
     if [ -f $JBOSS_PIDFILE ]; then
        read ppid < $JBOSS_PIDFILE
        if [ -d /proc/$ppid ]; then
            started=true
            break
        fi
     fi
  done

  # Workaround till we get all jboss starts removed from service group rpms delivered to iso.
  $_RM -f $WAIT_FILE

  until [ $count -gt $STARTUP_WAIT ]
  do
    status 2> /dev/null
    retCode=$?
    if [ $retCode -eq 0 ]; then
      launched=true
      break
    elif [ $retCode -eq 4 ]; then
      __process_hornetq_journals
    fi
    sleep 1
    let count=$count+1
  done


  if [ "$launched" = "false" ] ; then
    info "$prog failed to startup in the time allotted"
    failure
    echo
    return 1
  fi

  # Only create lock file upon successfull start of JBoss
  $_CAT /dev/null > "$JBOSS_LOCKFILE"

  info "Run post-start scripts"
  __run_scripts_in_directory $POST_START_DIR true

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
#   __process_hornetq_journals
#   validate hornetq journals
# Globals:
# Arguments:
# Returns:
#
#######################################
__process_hornetq_journals() {
if [ "$(ls -A $JOURNAL_DIRECTORY)" ]; then
   # need to create lock file atomically
   if ( set -o noclobber; > "$JOURNALS_MOVING_LOCK_FILE") 2> /dev/null
   then
      set +o noclobber
   else
      info " Checking for corrupted HornetQ journals is undergoing"
      set +o noclobber
      return
    fi
    $JOURNAL_SCRIPT $1 > /dev/null 2>&1 &
fi

}

#######################################
# Action :
#   status
# Globals:
#   MGT_USER
#   MGT_PASSWORD
#   JBOSS_PIDFILE
#   JBOSS_LOCKFILE
# Arguments:
#   None
# Returns:
#   0 Resource is started, DE(s) deployed
#   1 Resource is in failed state, pid file exists
#   2 Resource is in failed state, lock file exists
#   3 Resource is stopped or starting
#   4 Resource is running, HornetQ server is not active
#######################################
status() {

  if [ ! -f $JBOSS_PIDFILE ]; then
    echo "$prog is not running"
    return 3
  fi

  read ppid < $JBOSS_PIDFILE
  JB_MGMT_ADDR=$($_PS -f --pid $ppid 2> /dev/null | $_GREP $ppid 2> /dev/null | $_SED -e 's/.*jboss.bind.address.management=\(\S*\).*/\1/g' 2> /dev/null)
  if [ -z "$JB_MGMT_ADDR" ]; then
    echo "$prog dead but pid file exists"
    return 1
  fi

  if [ -s $HQ_FATAL_EXCEPTION_LOG ]
  then
    error "FATAL exception(s) occurred in HornetQ-Server, reporting status as unhealthy"
        __process_hornetq_journals "move_without_validation"
        return 5
  fi
  HORNETQ_STATUS=$(curl --digest -L -D - http://$JB_MGMT_ADDR:9990/management \
    --header 'Content-Type: application/json' \
    -d '{"operation":"read-attribute","address":[{"subsystem":"messaging"},{"hornetq-server":"default"}],"name":"active","json.pretty":1}' \
    -u $MGT_USER:$MGT_PASSWORD)

        if $_EGREP "result.*:.*true"<<<"$HORNETQ_STATUS"
        then
                echo "$prog is running"
                return 0
        fi

  JBOSS_STATUS=$(curl --digest -L -w 'RETURN_CODE=%{http_code}' -D - http://"$JB_MGMT_ADDR":9990/management \
    --header "Content-Type: application/json" \
    -d '{"operation":"read-attribute","name":"server-state","json.pretty":1}' \
    -u $MGT_USER:$MGT_PASSWORD)
        HTTP_CODE=$($_GREP "RETURN_CODE="<<<"$JBOSS_STATUS"|awk -F'RETURN_CODE=' '{print $2}')

        if $_EGREP "result.*:.*running"<<<"$JBOSS_STATUS"
        then
                error "$prog is running but HornetQ server is not active"
                return 4
        elif [ "$HTTP_CODE" == "503" ]
        then
                error "$prog process is running but $prog is not in good state"
                return 4
        elif [ -f $JBOSS_LOCKFILE ]
        then
      echo "$prog dead but lock file exists"
      return 2
        fi

  echo "$prog is not running"
  return 3
}

poststart
