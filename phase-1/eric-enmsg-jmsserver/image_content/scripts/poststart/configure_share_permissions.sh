#!/bin/bash

# UTILITIES
BASENAME=/bin/basename
CHOWN=/bin/chown

# GLOBAL VARIABLES
SCRIPT_NAME="${BASENAME} ${0}"
LOG_TAG="JMS"

#///////////////////////////////////////////////////////////////
# This function will print an error message to /var/log/messages
# Arguments:
#       $1 - Message
# Return: 0
#//////////////////////////////////////////////////////////////
error()
{
        logger -s -t ${LOG_TAG} -p user.err "ERROR ( ${SCRIPT_NAME} ): $1"
}

#//////////////////////////////////////////////////////////////
# This function will print an info message to /var/log/messages
# Arguments:
#       $1 - Message
# Return: 0
#/////////////////////////////////////////////////////////////
info()
{
        logger -s -t ${LOG_TAG} -p user.notice "INFORMATION ( ${SCRIPT_NAME} ): $1"
}

#######################################
# Action :
#   change_fs_permissons
#  This function will change the owner to jboss for specified sfs filesystems.
# Globals :
#   None
# Arguments:
#   None
# Returns:
#
#######################################
change_fs_permissons ()
{
  ARRAY_FS=(/ericsson/enm/dumps /ericsson/configuration_management/UpgradeIndependence)
  for _FS_ in "${ARRAY_FS[@]}"; do
    if [ -d "$_FS_" ]; then
      $CHOWN jboss_user:jboss "$_FS_"
          if [ $? -eq 0 ]; then
            info "Changed permission of $_FS_ successfully"
          fi
    else
          error "$_FS_ doesn't exist to change user permissions"
    fi
  done
}


#######################################
# Action :
#   main program
# Globals :
#   None
# Arguments:
#   None
# Returns:
#
#######################################

change_fs_permissons
