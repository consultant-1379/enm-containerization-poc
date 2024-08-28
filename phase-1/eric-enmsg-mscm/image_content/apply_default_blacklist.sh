#!/bin/bash

###########################################################################
# COPYRIGHT Ericsson 2018
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
# This script requires bash 4 or above
# $Date: 2018-01-25$
# $Author: Fergus Bartley$
# Script to update the blacklist file with default blacklist attributes
###########################################################################

_PIB_CONFIG_SCRIPT=/opt/ericsson/PlatformIntegrationBridge/etc/config.py

_MSCM_DIR=/ericsson/tor/data/mscm
_BLACKLIST_FILE=${_MSCM_DIR}/blacklist.csv
_MARKER_FILE=${_MSCM_DIR}/.blacklist_updated
_BLACKLIST_FILE_CONTENTS='#  Sample blacklist file, this explains the function of each column value
#
#  neType           =  defines the NetworkElement.neType value, Network Element Type, neType as defined on the NetworkElement MO
#  ossModelIdentity =  defines the NetworkElement.ossModelIdentity as defined on the NetworkElement MO
#                      Note: The wildcard value asterisk (*) can be used to apply blacklist towards all ossModelIdentities in ENM
#  mo               =  defines the Managed Object (Mo) type that needs to be filtered
#  attr             =  defines the Managed Object Attribute of the Managed Object to be filtered, An empty value indicates all attributes to be filtered
#  excludeFromSync  =  Boolean true/false, indicates if the attribute identified in the previous fields should be included during CM Sync read operations
#                      An Empty value defaults to true value
#                      false : Sync Filter Override feature, turn off Sync Filter , but retain the Notification filter
neType:ossModelIdentity:mo:attr:excludeFromSync'

_CHMOD=/bin/chmod
_CP=/bin/cp
_DIRNAME=/usr/bin/dirname
_MKDIR=/bin/mkdir
_RM=/bin/rm
_SED=/bin/sed
_LOCKFILE_CMD=/usr/bin/lockfile

__LOG_TAG=mscm

# DO NOT EDIT THESE LINES UNLESS YOU KNOW EXACTLY WHAT YOU ARE DOING, CONTACT ERICSSON SUPPORT IF IN ANY DOUBT
_BLACKLIST_MO_ATTRIBUTE_EXCLUDE_SYNC_1='ERBS:*:TermPointToENB:usedIpAddress:true'
_BLACKLIST_MO_ATTRIBUTE_EXCLUDE_SYNC_2='ERBS:*:ExternalENodeBFunction:gUGroupIdList:true'
declare -a _BLACKLIST_ATTRIBUTE_ARRAY=( "${_BLACKLIST_MO_ATTRIBUTE_EXCLUDE_SYNC_1}" "${_BLACKLIST_MO_ATTRIBUTE_EXCLUDE_SYNC_2}" )

#///////////////////////////////////////////////////////////////
# This function will print an error message to /var/log/messages
# Arguments:
#       $1 - Message
# Return: 0
#/////////////////////////////////////////////////////////////
error()
{
        logger -t ${__LOG_TAG} -p user.err "$1"
}

#//////////////////////////////////////////////////////////////
# This function will print an info message to /var/log/messages
# Arguments:
#       $1 - Message
# Return: 0
#/////////////////////////////////////////////////////////////
info()
{
         logger -t ${__LOG_TAG} -p user.notice "$1"
}

check_rc()
{
    cmd_rc=$1
    msg=$2
    if [[ $cmd_rc -ne 0 ]]; then
        error "$msg [rc = $cmd_rc]"
        # Clear lockfile
        ${_RM} -f "$LOCKFILE"
        exit "$cmd_rc"
    fi
}

check_rc_no_lock()
{
    cmd_rc=$1
    msg=$2
    if [[ $cmd_rc -ne 0 ]]; then
        error "$msg [rc = $cmd_rc]"
        exit "$cmd_rc"
    fi
}

###########################################################################
#
# Create the blacklist directory
#
###########################################################################
create_mscm_dir() {
   if  [[ ! -d ${_MSCM_DIR} ]]; then
        info "creating MSCM directory"
        $_MKDIR -m 700 "$_MSCM_DIR"
        check_rc_no_lock $? "FAILED TO CREATED DIRECTORY '$_MSCM_DIR'"
        $_CHMOD 755 "$_MSCM_DIR"
        check_rc_no_lock $? "FAILED TO SET PERMISSIONS ON '$_MSCM_DIR'"
        echo "$_BLACKLIST_FILE_CONTENTS" > "$_BLACKLIST_FILE"
        check_rc_no_lock $? "FAILED TO CREATE SAMPLE FILE '$_BLACKLIST_FILE'"
        $_CHMOD 755 "$_BLACKLIST_FILE"
        info  "created mscm directory and sample blacklist file"
    else
        info "mscm directory already exists "
    fi
  }

###########################################################################
#
# Apply default blacklist
#
###########################################################################
update_blacklist_file(){
    # Create lock file so only one MSCM can attempt to run "apply_default_blacklist.sh"
    LOCKFILE=${_MSCM_DIR}/apply_default_blacklist.lock
    ${_MKDIR} -p "$(${_DIRNAME} ${LOCKFILE})"

    info "Waiting for lock $LOCKFILE"
    if ${_LOCKFILE_CMD} -1 -r15 $LOCKFILE
    then
       info "Checking to see if marker file ${_MARKER_FILE} exists"
       if [[ ! -f ${_MARKER_FILE} ]]; then
          # Read Current Name of the Blacklist file from PIB
          info "Executing command '${_PIB_CONFIG_SCRIPT} read --app_server_address=$(hostname):8080 --name=blacklist_file_name | ${_SED} s'/__updated.*//''"
          blacklist_file=$(${_PIB_CONFIG_SCRIPT} read --app_server_address="$(hostname)":8080 --name=blacklist_file_name | ${_SED} s'/__updated.*//')
          check_rc $? "Error executing PIB read command, abandoning BlackList update,while reading current Blacklist   "
          info "Current Blacklist file is : ${blacklist_file}"

          # If Blacklist not defined in PIB use default Blacklist location
          if [[ $blacklist_file == "[]" ]]; then
              info "No existing Blacklist set , will use Empty Blacklist to build Default Blacklist"
              blacklist_file=${_BLACKLIST_FILE}
           else
              info "Backing up Existing Black list file with TimeStamp"
              ${_CP} ${blacklist_file} ${blacklist_file}_BACKUP_"$(date +%Y%m%d_%H%M%S)"
              check_rc $? "Unable to Backup Existing Black list file'${_BLACKLIST_FILE}'"
           fi

            # Confirm blacklist file is writable
            if [[ -w ${blacklist_file} ]] ; then
                   # Append new Default Blacklist values to BlackList file
                   for blacklistedAttribute in "${_BLACKLIST_ATTRIBUTE_ARRAY[@]}"
                       do
                          info "Updating blacklist file '${blacklist_file}' with values '${blacklistedAttribute}'"
                          echo "${blacklistedAttribute}" >> ${blacklist_file}
                       done

               # Apply Blacklist file changes via PIB Update command
               info "Blacklist_file is updated, running '${_PIB_CONFIG_SCRIPT} update --app_server_address=$(hostname):8080 --name=blacklist_file_name --value=${blacklist_file}'"
               ${_PIB_CONFIG_SCRIPT} update --app_server_address="$(hostname)":8080 --name=blacklist_file_name --value=${blacklist_file}
               check_rc $? "Error executing PIB update command, abandoning BlackList update, while applying new Blacklist "

               # Create "_MARKER_FILE" as the application of Blacklist in PIB has been successful
               touch ${_MARKER_FILE}
            else
               error "Error trying to upgrade BlackList file, ${blacklist_file} files unreachable"
            fi
        else
               info "Marker file ${_MARKER_FILE} already exists. Not going to update the Blacklist file"
        fi
    else
         # Unable to get access to the lockfile
         info "$(hostname) unable to update the Blacklist file, as script is already being run by other instance"
         exit 1
    fi
    # Clear lockfile
    ${_RM} -f $LOCKFILE
}

create_mscm_dir
update_blacklist_file

