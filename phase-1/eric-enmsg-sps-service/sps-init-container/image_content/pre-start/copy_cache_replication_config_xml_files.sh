#!/bin/bash

# UTILITIES
_GETSEBOOL=/usr/sbin/getsebool
_GREP=/bin/grep
_RESTORECON=/sbin/restorecon
_RSYNC=/usr/bin/rsync
_SEMANAGE=/usr/sbin/semanage
_SETSEBOOL=/usr/sbin/setsebool
_STAT=/usr/bin/stat

# GLOBAL VARIABLES
SCRIPT_NAME="${0}"
LOG_TAG="SPS_CONFIG"
SOURCE_DIR='/ericsson/enm/sps_cliconf'
NFS_SHARE='/var/ericsson/ddc_data'
DESTINATION_DIR=$NFS_SHARE/$(hostname)'_TOR/config'
SUPPORTED_ALGORITHMS_CACHE_CONFIG_XML="SupportedAlgorithmsCacheConfig.xml"
PKI_WEB_CLI_EXPORT_CACHE_CONFIG_XML="PkiWebCliExportCacheConfig.xml"
MAX_TIME_TO_WAIT=60

#######################################
# This function will print an info message to /var/log/messages
# Arguments:
#             $1 - Message
# Return: 0
#######################################
info(){
    logger -t ${LOG_TAG} -p user.info "( ${SCRIPT_NAME} ): $1"
}

#######################################
# This function will print a warning message to /var/log/messages
# Arguments:
#             $1 - Message
# Return: 0
#######################################
warn(){
    logger -t ${LOG_TAG} -p user.warning "( ${SCRIPT_NAME} ): $1"
}

#######################################
# This function will print a error message to /var/log/messages
# Arguments:
#             $1 - Message
# Return: 0
#######################################
error(){
    logger -t ${LOG_TAG} -p user.error "( ${SCRIPT_NAME} ): $1"
}

#######################################
# Action :
#    Confirm SELinux is for configured as
#    expected for rsync
# Globals :
#     SOURCE_DIR
# Arguments:
#     None
# Returns:
#
#######################################
setup_selinux() {
    info "SELinux: Changing security context of $SOURCE_DIR/"
    $_SEMANAGE fcontext -a -t rsync_data_t "$SOURCE_DIR/$1"
    $_RESTORECON -R $SOURCE_DIR

    if $_GETSEBOOL rsync_use_nfs | $_GREP off$; then
        info "SELinux: Allowing rsync to access nfs"
        $_SETSEBOOL -P rsync_use_nfs 1
    fi
}

#######################################
# Action :
#    Loop until NFS_SHARE is mounted
# Globals :
#     NFS_SHARE
# Arguments:
#     None
# Returns:
#
#######################################
wait_for_nfs() {
    retry_wait=1
    while [ "$($_STAT -f -L -c %T "$NFS_SHARE")" != "nfs" ]; do
        warn "$NFS_SHARE is not mounted - sleeping $retry_wait seconds"
        sleep $retry_wait
        retry_wait=$((retry_wait+1))

        if [ $retry_wait -gt $MAX_TIME_TO_WAIT ]; then
            error "Exiting - $NFS_SHARE is not mounted in $MAX_TIME_TO_WAIT seconds"
            exit 0
        fi
    done
}

#######################################
# Action :
#    Copy Files to NFS
#    All metadata files in SOURCE_DIR are
#    copied to DESTINATION_DIR.
# Globals :
#     SOURCE_DIR
#     DESTINATION_DIR
# Arguments:
#     None
# Returns:
#
#######################################
copy_files_to_nfs() {
    sleep_time=1
    total_sleep_time=0
    while ! $_RSYNC -craz "$SOURCE_DIR/$1" "$DESTINATION_DIR/$1"; do
        warn "Copy to NFS failed - retrying"
        sleep $sleep_time
        total_sleep_time=$(($total_sleep_time+$sleep_time))

        if [ $total_sleep_time -gt $MAX_TIME_TO_WAIT ]; then
            error "Exiting - $SOURCE_DIR/$1 has not been copied to $DESTINATION_DIR/$1 in $MAX_TIME_TO_WAIT seconds"
            exit 0
        fi
    done
}

#######################################
# Main
#######################################

# Check for Source File
if [ ! -f "$SOURCE_DIR/$SUPPORTED_ALGORITHMS_CACHE_CONFIG_XML" ] || [ ! -f "$SOURCE_DIR/$PKI_WEB_CLI_EXPORT_CACHE_CONFIG_XML" ]; then
    warn "Cache Config XML does not exist - exiting"
    exit 0
fi


setup_selinux $SUPPORTED_ALGORITHMS_CACHE_CONFIG_XML
setup_selinux $PKI_WEB_CLI_EXPORT_CACHE_CONFIG_XML

wait_for_nfs

copy_files_to_nfs $SUPPORTED_ALGORITHMS_CACHE_CONFIG_XML
copy_files_to_nfs $PKI_WEB_CLI_EXPORT_CACHE_CONFIG_XML