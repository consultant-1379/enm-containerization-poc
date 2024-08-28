#!/bin/bash
###################################################################################
# COPYRIGHT Ericsson 2016                                                         #
# The copyright to the computer program(s) herein is the property of              #
# Ericsson Inc. The programs may be used and/or copied only with written          #
# permission from Ericsson Inc. or in accordance with the terms and               #
# conditions stipulated in the agreement/contract under which the                 #
# program(s) have been supplied.                                                  #
# $Author: Rakesh K Shukla$                                                       #
###################################################################################


################################################################################
# This method commits external cache to conntrack table then it flushes
# internal and external caches , then it forces a resync against the kernel 
# connection tracking table and at last it does a bulk send to backup lvsrouter
################################################################################

CONNTRACKD=conntrackd
CONNTRACKD_CONFIG=/etc/conntrackd/conntrackd.conf
trigger_master()
{
    echo "trigger_master() called"
    $CONNTRACKD -C $CONNTRACKD_CONFIG -c
    if [ $? == 0 ]
    then
        echo "Successfully commited external cache"
    else
        echo "Failed to commit external cache"
    fi
    $CONNTRACKD -C $CONNTRACKD_CONFIG -f
    if [ $? == 0 ]
    then
        echo "Successfully flushed caches"
    else
        echo "Failed to flush caches"
    fi
    $CONNTRACKD -C $CONNTRACKD_CONFIG -R
    if [ $? == 0 ]
    then
        echo "Successfully resynchronized internal cache with kernel table"
    else
        echo "Failed to resynchronize internal cache with kernel table"
    fi
    $CONNTRACKD -C $CONNTRACKD_CONFIG -B
    if [ $? == 0 ]
    then
        echo "Successfully sent bulk update to backup"
    else
        echo "Failed to send bulk update to backup"
    fi
}
################################################################################
# This method checks if conntrackd is running if not it starts it
# then it resets in-kernel timers to remove stale entries, then requests 
# resync from master lvsrouter
################################################################################
trigger_backup()
{
    echo "trigger_backup() called"
    $CONNTRACKD -C $CONNTRACKD_CONFIG -s
    if [ $? != 0 ]
    then
    	if [ -f $CONNTRACKD_LOCK ]
        then
            echo "conntrackd not running but lock file exists"
            $RM $CONNTRACKD_LOCK
        fi
        start_conntrackd
        if [ $? != 0 ]
        then
            echo "Failed to start conntrackd"
            exit 1
        fi
	fi
	$CONNTRACKD -C $CONNTRACKD_CONFIG -t
    if [ $? == 0 ]
    then
        echo "Successfully shortened kernel timers"
    else
        echo "Failed to shorten kernel timer"
    fi
    $CONNTRACKD -C $CONNTRACKD_CONFIG -n
    if [ $? == 0 ]
    then
        echo "Successfully requested resync with master"
    else
        echo "Failed to request resync with master"
    fi
}
################################################################################
# Resets in-kernel timers to remove stale entries, then requests 
# resync from master lvsrouter
################################################################################
trigger_fault()
{
    echo "trigger_fault() called"
    $CONNTRACKD -C $CONNTRACKD_CONFIG -t
    if [ $? == 0 ]
    then
        echo "Successfully shortened kernel timers"
    else
        echo "Failed to shorten kernel timer"
    fi
}

case "$1" in
  master)
    trigger_master
    ;;
  backup)
    trigger_backup
    ;;
  fault)
    trigger_fault
    ;;
  *)
    echo "Invalid parameter passed to script:$1"
    exit 1
    ;;
esac
exit 0
