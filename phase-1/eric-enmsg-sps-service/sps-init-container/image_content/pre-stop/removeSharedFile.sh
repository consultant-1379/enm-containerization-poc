#!/bin/bash
##########################################################################
# COPYRIGHT Ericsson 2017
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################
#
# This script should be executed as a jboss pre_stop in SPS service group
#
################################################ 
#  Variables
################################################ 

SHARED_DIR=/ericsson/tor/data/credm/hosts

logger -t CREDENTIAL_MGR_SPS -p user.notice "Remove shared file script STARTED"
`timeout 10s test -e ${SHARED_DIR}`
if [[ $? -eq 0 ]] ; then
    filename=$(hostname)
    `timeout 10s ls ${SHARED_DIR}/$filename > /dev/null 2>&1`
    status=$?

    if [ "$status" -eq 0 ] ; then 
       `timeout 10s /bin/rm -f /ericsson/tor/data/credm/hosts/$filename`
       logger -t CREDENTIAL_MGR_SPS -p user.notice "Removed shared file $filename" 
    else
       logger -t CREDENTIAL_MGR_SPS -p user.notice "$filename isn't present in ${SHARED_DIR} or timeout accessing NFS"
    fi
else 
    logger -t CREDENTIAL_MGR_SPS -p user.notice "${SHARED_DIR} doesn't exist or timeout accessing NFS"
fi
logger -t CREDENTIAL_MGR_SPS -p user.notice "Remove shared file script FINISHED"
