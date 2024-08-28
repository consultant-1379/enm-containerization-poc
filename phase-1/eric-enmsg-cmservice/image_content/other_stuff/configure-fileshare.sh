#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2015
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################
logger "configure-fileshare.sh"

# UTILITIES

CHOWN="/bin/chown -R"
GREP=/bin/grep
MKDIR="/bin/mkdir -p"

# GLOBAL VARIABLES

CONFIG_MGT="config_mgt"
MOUNTS_FILE="/proc/mounts"
STARTUP_WAIT=600

# IMPEXP DIRS

FILE_SHARE="/ericsson/config_mgt"
FILE_SHARE_SUB_DIR="$FILE_SHARE/script_engine"
FILE_SHARE_IMPORT_SUB_DIR="$FILE_SHARE/import_files"

#######################################
# Action :
#   __wait_for_file_share
#  Create directories on the SFS share
# Globals :
#   STARTUP_WAIT
#   MOUNTS_FILE
# Arguments:
#   None
# Returns:
#   Return Code to allow Main Program decide to create FS or not
#######################################
__wait_for_file_share()
{
_INIT_=0
while [[ $_INIT_ -lt $STARTUP_WAIT ]]
do
  $GREP "$CONFIG_MGT" $MOUNTS_FILE > /dev/null
  if [[ $? -ne 0 ]]; then
    logger "SFS not ready - waiting"
	sleep 1
	((_INIT_++))
	ret_code=1
  else
    logger "SFS is ready"
	ret_code=0
	break
  fi
done
return $ret_code
}

#######################################
# Action :
#   __create_fs_dir
#  Create the expected dir & set permissions
# Globals :
#   None
# Arguments:
#   None
# Returns:
#
#######################################
__create_fs_dir ()
{
FILE_SHARE_DIR=$1

logger "entering method __create_fs_dir"

if [ -d "$FILE_SHARE_DIR" ]; then
  logger "${FILE_SHARE_DIR} already exists. Proceeding with configuration"
else
  logger "Creating ${FILE_SHARE_DIR}"
  ${MKDIR} ${FILE_SHARE_DIR}
  logger "Changing ownership of ${FILE_SHARE_DIR}"
  $CHOWN jboss_user:jboss "$FILE_SHARE_DIR"
fi
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

__wait_for_file_share
if [[ $? -ne 0 ]]; then
    logger "File Share configuration has timed out waiting for the SFS share to become available."
    logger "This will adversely affect functionality - Please contact your System Administrator"
    exit 1
else
    logger "File Share is ready, creating ${FILE_SHARE_SUB_DIR} and ${FILE_SHARE_IMPORT_SUB_DIR}"
    __create_fs_dir $FILE_SHARE_SUB_DIR
    __create_fs_dir $FILE_SHARE_IMPORT_SUB_DIR
fi

exit 0
