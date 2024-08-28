#!/bin/sh

set -o xtrace

JBOSS_HOME=../


if [ `whoami` != 'jboss_user' ]
then
     printf "ERROR: This script must be ran as jboss_user.\n"
     exit 1
fi


if [ -z "$JBOSS_HOME" ]
then

	printf "ERROR: JBOSS_HOME must be set.\n"

	exit 1
fi

if [ -d "$JBOSS_HOME/common" ]
then

java -Djava.util.logging.config.file=~/Library/Apache/log4j.properties -cp $JBOSS_HOME/common/lib/hornetq-logging.jar:$JBOSS_HOME/common/lib/hornetq-core.jar:$JBOSS_HOME/common/lib/netty.jar org.hornetq.core.persistence.impl.journal.PrintData $1 $2

fi

if [ -d "$JBOSS_HOME/standalone" ]
then

	cd $JBOSS_HOME

	__classpath=""
	for file in `find . -name 'hornetq*.jar'`
	do
		printf "INFO: file = %s\n", $file
	    __classpath=${__classpath}:${file}
    	done

	for file in `find . -name 'netty*.jar'`
	do
           __classpath=${__classpath}:${file}
	done

        for file in `find . -name 'jboss-logging*.jar'`
        do
           __classpath=${__classpath}:${file}
        done


    __logging=`find . -samefile 'modules/system/layers/base/org/jboss/logging/main/jboss-logging-3.1.2.GA-redhat-1.jar'`

    __classpath=$__classpath:$__logging

    printf "INFO: classpath = %s\n" $__classpath

java -Djava.util.logging.config.file=~/Library/Apache/log4j.properties -cp $__classpath org.hornetq.core.persistence.impl.journal.PrintData $1 $2

fi
