#!/bin/bash

#
# enmCertificates     init script to manage service certificates
#
# chkconfig: 2345 90 35
# description: call the credentialmanager standalone service.
#

#
#       /etc/rc.d/init.d/<servicename>
#
#       <description of the *service*>
#       <any general comments about this init script>
#
# <tags -- see below for tag definitions.  *Every line* from the top
#  of the file to the end of the tags section must begin with a #
#  character.  After the tags section, there should be a blank line.
#  This keeps normal comments in the rest of the file from being
#  mistaken for tags, should they happen to fit the pattern.>

# Source function library.
. /etc/init.d/functions

#define any local shell functions used by the code that follows

LOG_DIRECTORY=/var/log/enmcertificates/
LOG_NAME=enmCertificatesLocal.log
COMMAND=/etc/init.d/enmCertificates
CREDEMCLIKS=/ericsson/credm/cli/data/certs/credmApiKS.JKS
_PIDOF=/sbin/pidof

PRE_START_DIR="/ericsson/credm/cli/script/pre-start"

startLocal() {
	touch $LOG_DIRECTORY/$LOG_NAME
	echo `date` >> $LOG_DIRECTORY/$LOG_NAME

        if [[ -e $CREDEMCLIKS ]];
	then
		echo "Nothing to do $CREDEMCLIKS already exists" >> $LOG_DIRECTORY/$LOG_NAME
	else
		echo "Launch $COMMAND start" >> $LOG_DIRECTORY/$LOG_NAME
             #   if [ $(${_PIDOF} init) ]; then
                    $COMMAND start local
             #   elif [ $(${_PIDOF} systemd) ]; then
             #       SYSTEMCTL_SKIP_REDIRECT=1 $COMMAND start local
             #   else
             #       echo "Cannot find a compatible init service!" >> $LOG_DIRECTORY/$LOG_NAME
             #       exit 1
             #   fi
	fi
}

runScriptsInDirectory() {
    for SCRIPT in $1/*
    do
         if [ -f "$SCRIPT" -a -x "$SCRIPT" ]
         then
               logger -p user.info "CredentialManager CLI execute script : $SCRIPT"
               $SCRIPT > /dev/null 2>&1 
               if [ $? -ne 0 ]; then
                    logger -p user.warning "Script : $SCRIPT exits with code $?"
               else
                    logger -p user.info "Script : $SCRIPT exits with code $?"
               fi
            fi
     done
}


runScriptsInDirectory $PRE_START_DIR
startLocal
echo `date` >> $LOG_DIRECTORY/$LOG_NAME
exit $?
