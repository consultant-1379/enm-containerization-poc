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
readonly CP="/bin/cp -f"
readonly MV="/bin/mv -f"
readonly IP="/sbin/ip -4"
readonly GREP="/bin/grep"
readonly AWK="/bin/awk"
readonly ECHO="/bin/echo"
readonly HOSTNAME="/bin/hostname"
readonly LSMOD="/sbin/lsmod"
readonly MODPROBE="/sbin/modprobe"
readonly SED="/bin/sed"
readonly RM="/bin/rm -f"
readonly TR="/usr/bin/tr"
readonly SORT="/bin/sort"
readonly IPCALC="/bin/ipcalc"
readonly SYSTEMCTL="/bin/systemctl"
readonly TOUCH="/bin/touch"
readonly XMLLINT="/usr/bin/xmllint"
readonly CONNTRACKD="/usr/sbin/conntrackd"
readonly IPTABLES="/usr/sbin/iptables -w 10"
readonly IP6TABLES="/usr/sbin/ip6tables -w 10"
readonly CONNTRACKD_DAEMON="conntrackd"
readonly CONNTRACK="/usr/sbin/conntrack"
readonly IFCONFIG="/usr/sbin/ifconfig"
readonly SYSCTL="/sbin/sysctl"
readonly SYSCTL_DIR="/etc/sysctl.d"
readonly EXPIRE_NODEST_CONN="net.ipv4.vs.expire_nodest_conn"
readonly NF_CONNTRACK_MAX="net.netfilter.nf_conntrack_max"
readonly PYTHON="/usr/bin/python"
readonly MKDIR="/bin/mkdir"


readonly NL=$'\\n'
readonly LOG_TAG="LVSROUTER"
LVS_CONFIG_ROOT="/ericsson/enm/lvsrouter/etc"
LVS_BIN_ROOT="/ericsson/enm/lvsrouter/bin"
KEEPALIVED_CONFIG_ROOT="/etc/keepalived"
GLOBAL_CONFIG="/ericsson/tor/data/global.properties"
SFS_WAIT_LOCK_FILE="$LVS_CONFIG_ROOT/sfs_wait.lock"
CONNTRACKD_ENM_CONFIG_GENERATED="$LVS_CONFIG_ROOT/conntrackd_generated.conf"
CONNTRACKD_ENM_CONFIG="$LVS_CONFIG_ROOT/conntrackd.conf"
CONNTRACKD_CONFIG="/etc/conntrackd/conntrackd.conf"
CONNTRACKD_LOCK="/var/lock/conntrack.lock"
enm_lvs_config="$LVS_CONFIG_ROOT/keepalived.conf"
enm_keepalived_config="$KEEPALIVED_CONFIG_ROOT/enm_keepalived.conf"
TEMPLATE_CONFIG="$LVS_CONFIG_ROOT/keepalived_template.xml"
IPTABLES_CUSTOMIZATION="/ericsson/tor/data/lvsrouter/"
IPTABLES_CUSTOMIZATION_LOCAL="/ericsson/enm/lvsrouter/etc/iptable_rules"
enm_lvs_instances_config="/etc/conntrackd/lvs_instances"
keepalivedstatefileprefix="/var/run/keepalived.state"
groups_to_check_on_backup="/ericsson/tor/data/backup.groups"
DEPLOYMENT_TYPE="/ericsson/enm/lvsrouter/etc/deploymenttype"


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
