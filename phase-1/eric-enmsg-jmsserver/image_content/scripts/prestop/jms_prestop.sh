#!/bin/sh
#########################################
#
# Post start hook
# Check jboss is running and run post starts
#
###########################################
#set -x  
source /ericsson/3pp/jboss/container-jms-jboss 


stop() {

	info $"Stopping $prog: "
	count=0;
	
	if [ -f $JBOSS_PIDFILE ]; then

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

	if [ -f $WAIT_FILE ]; then
        $_RM -f $WAIT_FILE
    fi

    if [ -f $JOURNALS_MOVING_LOCK_FILE ]; then
        $_RM -f $JOURNALS_MOVING_LOCK_FILE
    fi

    info "Run post-stop scripts"
    __run_scripts_in_directory $POST_STOP_DIR true

	if $_RM -f $HQ_FATAL_EXCEPTION_LOG
	then
		info "Successfully deleted $HQ_FATAL_EXCEPTION_LOG"
	else
		error "Failed to delete $HQ_FATAL_EXCEPTION_LOG"
	fi
    # sleep for 40 seconds in case of any JMS client gets stuck
    # see https://jira-nam.lmera.ericsson.se/browse/TORF-136167
    # [RedHat 01675923] for details
    sleep 40s

    success
    echo
}

stop
