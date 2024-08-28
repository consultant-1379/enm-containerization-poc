#!/bin/sh
#set -x
###################################################
#
# ENTRY POINT SCRIPT FOR JBOSS
# 
#
#################################################### 
service rsyslog start

source /ericsson/3pp/jboss/container-jms-jboss

#####################################################
#
#PREDEPLOY DEPLOY POST-START EXECUTED WHEN JBOSS
#STARTED
#
##################################################### 
bash /ericsson/3pp/jboss/container_post_start.sh & 
 
####################################################
#
#JBOSS START ON FOREGROUND
#
####################################################

[ -r "$STANDALONE_CONF" ] && . "${STANDALONE_CONF}"

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

  NUMACTL_VALUE=""
  # Check HW type
  if [[ $(/usr/sbin/dmidecode -t system | /bin/grep Product | /bin/awk '{print $5}') == Gen9 ]]; then
      if [ ! -z "$NUMACTL_JMS_G9" ]; then
          NUMACTL_VALUE=${NUMACTL_JMS_G9}
      fi
  else
      if [ ! -z "$NUMACTL_JMS" ]; then
          NUMACTL_VALUE=${NUMACTL_JMS}
      fi
  fi

  info "NUMACTL configuration used for starting JMS Server : ($NUMACTL_VALUE)"

##########################################################
#
#JBOSS_SCRIPT /ericsson/3pp/jboss/bin/standalone.sh
#
##########################################################
sed -i "7 a JAVA_OPTS=\'$JAVA_OPTS\'" $JBOSS_SCRIPT
info "Executing su with parameters Jboss user = $JBOSS_USER , JBOSS_PIDFILE = $JBOSS_PIDFILE JAVA_OPTSi = $JAVA_OPTS"
su - $JBOSS_USER -c "LAUNCH_JBOSS_IN_BACKGROUND=1 JBOSS_PIDFILE=$JBOSS_PIDFILE $NUMACTL_VALUE $JBOSS_SCRIPT -c $JBOSS_CONFIG" 2>&1 > $JBOSS_CONSOLE_LOG 
