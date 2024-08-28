#!/bin/sh 

_MKDIR=/bin/mkdir

_TOUCH=/bin/touch

_RM=/bin/rm

_NC=/usr/bin/nc

_NMAP=/bin/nmap

_LS=/bin/ls

_PS="/bin/ps"

_GREP="/bin/grep"

_SED="/bin/sed"

_ECHO='/bin/echo'

_AWK='/bin/awk'

_PIDOF=/sbin/pidof

DPS_JPA_EAR_GENERATED_SHARED_FOLDER=/ericsson/tor/data/dps/ERICdpsupgrade/dps-jpa-ear/runtime


# Source jboss logger methods
. $JBOSS_HOME/bin/jbosslogger

DPS_PERSISTENCE_PROVIDER=""

get_dps_provider()
{
    if [ -z "$DPS_PERSISTENCE_PROVIDER" ]
    then
        DPS_PERSISTENCE_PROVIDER="$($_GREP "^dps_persistence_provider=" $GLOBAL_CONFIG|$_AWK -F'=' '{print $2}')"
    fi
}

__is_postgres_running(){
    $(echo > /dev/tcp/postgresql01/5432) >/dev/null 2>&1
    postgresrc=$?
    if [ "$postgresrc" -eq 0 ] ; then
        POSTGRES_SERVER_RUNNING=true
    else
        POSTGRES_SERVER_RUNNING=false
    fi
}

#######################################
# Action :
#   __is_jmsserver_running
#   Check if the jmsserver is running
# Globals :
#   GLOBAL_CONFIG
#   JMS_SERVER_RUNNING
# Arguments:
#   None
# Returns:
#   0 jmsserver is running
#   1 jmsserver is not running
#   2 jmsserver is running but not
#     fully started
#######################################
__is_jmsserver_running() {

    #if [ $($_PIDOF systemd) ] ; then
    #    $_NMAP -Pn -p5445 jms01 --system-dns | grep "^5445/tcp.*open" >/dev/null 2>&1
    #elif [ $($_PIDOF init)  ] ; then
       # /usr/bin/nc could hang if jms is not up , "-w" timesout 2 seconds
        $_NC -z jms01 5445 -w 2 >/dev/null 2>&1
    #else
        #error "Error: Failed to find any service system."
        #exit 1
    #fi
    jmsrc=$?

    if [ "$jmsrc" -eq 0 ] ; then
        _check_file "$JMS_SERVER_RUNNING" "1"
        jmsfilerc=$?
        if [ "$jmsfilerc" -eq 1 ] ; then
            return 2
        else
            return 0
        fi
    else
        return 1
    fi
}

#######################################
# Action :
#   _check_sfs_files
#   Checks if required sfs files are accessible
# Returns:
#  0 if all files are accessible
#  1 if all files are not accessible
#######################################

_check_sfs_files(){
     _check_file "$MODEL_REPO"
    modelrc=$?
    _check_file "$GLOBAL_CONFIG"
    globalrc=$?
    _check_file "$ROOTCACERT_FILE"
    rootrc=$?
    if [[  "$modelrc" == 0 && "$globalrc" == 0 && "$rootrc" == 0 ]]; then
         return 0
    else
         return 1
    fi

}

#######################################
# Action :
#   __wait_for_sfs_dps_jms_postgres
#  Don't want to start until
#  1. we have access to shared file system i.e
#  the models,global.properties and rootCA.pem
#  2. DPS EAR has been generated
#  3. JMS server is running
#  4. Postgres is available
#  Note: conditions 2 and 3 are ignored if the
#  current JBoss instance is JMS server
# Globals :
#   MODEL_REPO
#   GLOBAL_CONFIG
#   STARTUP_WAIT
#   JMS_SERVER_RUNNING
#   POSTGRES_SERVER_RUNNING
#   POSTGRES_REQUIRED
# Arguments:
#   None
# Returns:
#
#######################################
__wait_for_sfs_dps_jms_postgres() {

# Workaround till we get all jboss starts removed from service group rpms delivered to iso.
        if [ "$command" == "start" ] ; then
                if [ -f "$WAIT_FILE" ]; then

                        info "$WAIT_FILE"
                        info "Waiting for SFS already in previous jboss command"
                        exit 3
                else
                        timeout 2 $_TOUCH $WAIT_FILE
                        info "wait file creation return code: $?"
                fi
        fi

    status=0
    wait=1
    while ! _check_sfs_files
    do
        if [ "$wait" -gt "$STARTUP_WAIT" ]; then
            break
        fi
        info "SFS not ready - waiting"
        sleep 1
        let wait=$wait+1;
    done
    _check_sfs_files
    if [ "$?" -eq 1 ]; then
        status=1
        error "SFS is not ready - timed out"
    fi
    get_dps_provider
    if [ "$DPS_PERSISTENCE_PROVIDER" != "neo4j" ]; then
        while [ "$(ls -A  "${DPS_JPA_EAR_GENERATED_SHARED_FOLDER}")" == "" ]
        do
            if [ "$wait" -gt "$STARTUP_WAIT" ]; then
               break
            fi
            info "DPS JPA EAR not generated yet -- waiting for 1 second"
            sleep 1
            let wait=$wait+1;
        done
        if [[ "$(ls -A  "${DPS_JPA_EAR_GENERATED_SHARED_FOLDER}")" == "" ]]; then
           status=1
           error "DPS JPA EAR is not ready - timed out"
        fi
    fi
        while ! __is_jmsserver_running
        do
                if [ "$wait" -gt "$STARTUP_WAIT" ]; then
                        break
                fi
                info "JMS server not running - waiting"
                sleep 1
                let wait=$wait+1;
        done
        __is_jmsserver_running
        if [ "$?" -ne 0 ]; then
                status=1
                error "JMS server is not ready - timed out"
        fi

        if [[ "$POSTGRES_REQUIRED" == "true" ]]; then
                POSTGRES_SERVER_RUNNING=false

                while [[ "$POSTGRES_SERVER_RUNNING" == "false" ]]
                do
                        if [ "$wait" -gt "$STARTUP_WAIT" ]; then
                                break
                        fi

                        __is_postgres_running
                        info "Postgres server not running - waiting"
                        sleep 1
                        let wait=$wait+1;
                done
                if [[ "$POSTGRES_SERVER_RUNNING" == "false" ]]; then
                        status=1
                        error "Postgres server is not ready - timed out"
                fi
        fi

        echo $status
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
    TIMEOUT=2
    if [ "x$2" != "x" ]; then
      TIMEOUT=$2
    fi

    timeout $TIMEOUT ls "$1" > /dev/null 2>&1
    lsrc=$?
    if [ "$lsrc" -eq 0 ]; then
      return 0
    else
      return 1
    fi
}


#######################################
# Action :
#   __check_service_avalability
#   Checks and wait for SFS, DPS and
#   JMS to be ready.
# Globals:
#   STANDALONE_CONF
#   PIB_ADDRESS
#       JB_INTERNAL
# Arguments:
#   None
# Returns:
#
#######################################
__check_service_avalability() {

    status=0

    if [ "$command" == "start" ]; then

        # Order is important here. Must wait for the SFS, DPS EAR,
        # and JMS server to be ready before loading standalone.conf
        status=$(__wait_for_sfs_dps_jms_postgres)
    fi

    if [ "$status" == "1" ]; then
        timeout 2 $_RM -f $WAIT_FILE
    fi

    echo $status
}


__check_service_avalability
