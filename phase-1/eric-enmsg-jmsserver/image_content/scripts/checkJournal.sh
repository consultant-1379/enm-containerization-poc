#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2016
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
# 
#$Date: 18-11-2016$
# $Author: Maksudur Rahman$
#
# This script is responsible to detect HornetQ corrupt journal
###########################################################################
CLASSPATH=""
if [ `whoami` != 'jboss_user' ]
then
     printf "ERROR: This script must be ran as jboss_user.\n"
     exit 1
fi
if [ "$JBOSS_HOME" == "" ]
then
        JBOSS_HOME=/ericsson/3pp/jboss
fi
export JBOSS_HOME
# Source jms logger methods
. $JBOSS_HOME/bin/jmslogger

if [ -d "$JBOSS_HOME/standalone" ]
then

        for file in $(find $JBOSS_HOME/modules -name 'hornetq*.jar' -o -name 'netty*.jar' -o -name 'jboss-logging*.jar'); do
              CLASSPATH=${CLASSPATH}:${file}
        done
		hornetq_utility_jar=$(find $JBOSS_HOME/bin -name hornetq-utility*.jar)
        CLASSPATH="$hornetq_utility_jar$CLASSPATH"
        info "classpath - $CLASSPATH "
        java_output=$(java -Djava.util.logging.config.file=~/Library/Apache/log4j.properties -cp $CLASSPATH  com.ericsson.oss.itpf.jboss.jmsconfig.journal.PrintData $1 $2 2>&1)
		java_output_result=$?
		info "HornetQ journal validator java program exit code:$java_output_result"
		if (( $java_output_result != 0 ))
		then
			error "HornetQ journal validator java progem failed , journals may be corrupt:$java_output"
		fi
        exit $java_output_result
else
        exit 255
fi
