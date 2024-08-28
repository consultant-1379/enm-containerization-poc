#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2018
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################

MKDIR=/bin/mkdir
CHMOD=/bin/chmod
CHOWN=/bin/chown

JBOSS_USER="jboss_user"
JBOSS_GROUP="jboss"

NETEX_BASE_DIR="/ericsson/config_mgt/netex"
NETEX_BASE_DIR_PERMISSIONS=755

#######################################
# Action :
#   Creates netex directories on the shared file system
# Globals :
#   None
# Arguments:
#   None
# Returns:
#
#######################################
createUsageExportDirectories()
{
  if [[ ! -d ${NETEX_BASE_DIR} ]]; then
    logger "Netex directory not exist, creating ${NETEX_BASE_DIR}"
    ${MKDIR} ${NETEX_BASE_DIR}
    if [ $? -ne 0 ]; then
      logger "${NETEX_BASE_DIR} can not be created now."
      return 1
    fi
  fi
}

#######################################
# Action :
#   Changing the folder permissions
# Globals :
#   None
# Arguments:
#   None
# Returns:
#
#######################################
change_fs_permissons ()
{
  _RET_CODE_=0
  ARRAY_FS=(/ericsson/config_mgt ${NETEX_BASE_DIR})
  for _FS_ in "${ARRAY_FS[@]}"; do
    if [ -d $_FS_ ]; then
      username=$(/bin/ls -ld $_FS_ | awk '{print $3}')
      if [ "$username" != ${JBOSS_USER} ]; then
        ${CHOWN} -R ${JBOSS_USER}:${JBOSS_GROUP} $_FS_ || __error "Unable to change the ownership to $JBOSS_USER"
        ${CHMOD} -R ${NETEX_BASE_DIR_PERMISSIONS} $_FS_ || __error "Unable to set permissions"
        logger "Changed ownership of $_FS_"
      fi
    else
      # Return error if the directory is not created yet
      logger "The directory: $_FS_ is not created yet"
      _RET_CODE_=1
    fi
  done
  return $_RET_CODE_
}

#######################################
# Action :
#   Safe execute the function with retry
# Globals :
#   None
# Arguments:
#   $1  The function name to execute
#   $2  How many times to retry(the interval between each retry is 1 second)
# Returns:
#
#######################################
safe_execute_with_retry ()
{
  _FUNC_=$1
  _TIMEOUT_=$2
  _INIT_=0
  _DONE_=1
  while [ $_INIT_ -lt $_TIMEOUT_ ] && [ $_DONE_ -ne 0 ]; do
    $_FUNC_
    _DONE_=$?
    sleep 1
    ((_INIT_++))
  done
}

#######################################
# Action :
#   Main program
# Globals :
#   None
# Arguments:
#   None
# Returns:
#
#######################################

logger "Running Netex Group RPM pre-start"

logger "Prepare to create the usage export folder"
safe_execute_with_retry createUsageExportDirectories 3

logger "Running change file ownership in background"
safe_execute_with_retry change_fs_permissons 300 &

logger "Netex Group RPM pre-start completed"

exit 0