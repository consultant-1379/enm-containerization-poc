#!/bin/bash -x
#------------------------------------------------------------------------------#
# Logging level:  0 - Logs are off. Only general messages are displayed.       #
#                 4 - DEBUG                                                    #
#                 3 - INFO                                                     #
#                 2 - WARN                                                     #
#                 1 - ERROR                                                    #
#------------------------------------------------------------------------------#
LOG_LEVEL=4
#------------------------------------------------------------------------------#
# Check if openidm.properties file exists and source it first for all the data needed for further operations
OPENIDM_PROPERTIES=/ericsson/tmp/openidm/bin/openidm.properties

 if [ ! -r "$OPENIDM_PROPERTIES" ]; then
   /usr/bin/logger "File: openidm.properties not found."
  fi
  source $OPENIDM_PROPERTIES
if [ $? != 0 ] ; then
  /usr/bin/logger "ERROR: Failed to source $OPENIDM_PROPERTIES."
   exit 1
fi

#------------------------------------------------------------------------------#
# Function:    SetLogFile                                                      #
# Description: This functions creates installation log file.                   #
# Parameters:  nothing                                                         #
# Returns:     0 - Success                                                     #
#------------------------------------------------------------------------------#
SetLogFile()
{
   # Create the log directory if it does not already exist 
   if [ ! -d "$LOG_DIR" ] ; then
      "$MKDIR" -p "$LOG_DIR"
      if [ $? != 0 ] ; then
         "$LOGGER" "Failed to create $LOG_DIR"
         exit 1
      fi
   fi

   # Set SELinux context for $LOG_DIR
   #/usr/sbin/semanage fcontext -a -t var_log_t "$LOG_DIR(/.*)?"
   #if [ $? != 0 ] ; then
   #   "$LOGGER" "Failed to create SELinux rule for logs in $LOG_DIR"
   #   exit 0
   #fi

   #/sbin/restorecon -R $LOG_DIR
   #if [ $? != 0 ] ; then
   #   "$LOGGER" "Failed to set security context for files in $LOG_DIR"
   #   exit 1
   #fi

   # Create the command log directory if it does not already exist
   if [ ! -d "$INST_TMP" ] ; then
      "$MKDIR" -p "$INST_TMP"
      if [ $? != 0 ] ; then
         "$LOGGER" "Failed to create $INST_TMP"
         exit 1
      fi
   fi
   
   # Create new install log
    if [ ! -e "$LOG_FILE" ]; then
       "$TOUCH" "$LOG_FILE"
       if [ $? != 0 ] ; then
          "$LOGGER" "Failed to create $LOG_FILE"
          exit 1
       fi
    fi
   # Change permission on log file to rw to all
   "$CHMOD" 666 "$LOG_FILE" 
   if [ $? != 0 ] ; then
      "$LOGGER" "Failed to set permssions on $LOG_FILE"
      exit 1
   fi

   # Change owner to openidm
   changeOwnership "$LOG_DIR"
   
   return 0
}


#------------------------------------------------------------------------------#
# Function:    logDebug                                                        #
# Description: This functions prints debug messages into the log file.         #
#------------------------------------------------------------------------------#
logMessage()
{ 
   local time_stamp
   time_stamp=$("$DATE" "+%F:%H:%M:%S%:z")
   local msg="$time_stamp: $1"
   "$LOGGER" "$msg"
   "$ECHO" "$msg" >> "$LOG_FILE"
}

#------------------------------------------------------------------------------#
# Function:    logError                                                        #
# Description: This functions prints error messages into the log file.         #
#------------------------------------------------------------------------------#
logError()
{
  if [ "$LOG_LEVEL" -ge 1  ]; then
    local time_stamp
    time_stamp=$("$DATE" "+%F:%H:%M:%S%:z")
    local msg="$time_stamp: [ERROR] $1"
    "$LOGGER" "$msg"
    "$ECHO" "$msg" >> "$LOG_FILE"
  fi
}

#------------------------------------------------------------------------------#
# Function:    logWarn                                                         #
# Description: This functions prints warning messages into the log file.       #
#------------------------------------------------------------------------------#
logWarn()
{
  if [ "$LOG_LEVEL" -ge 2  ]; then
    local time_stamp
    time_stamp=$("$DATE" "+%F:%H:%M:%S%:z")
    local msg="$time_stamp: [WARN] $1"
    "$LOGGER" "$msg"
    "$ECHO" "$msg" >> "$LOG_FILE"
  fi
}

#------------------------------------------------------------------------------#
# Function:    logInfo                                                         #
# Description: This functions prints info messages into the log file.          #
#------------------------------------------------------------------------------#
logInfo()
{
  if [ "$LOG_LEVEL" -ge 3  ]; then
    local time_stamp
    time_stamp=$("$DATE" "+%F:%H:%M:%S%:z")
    local msg="$time_stamp: [INFO] $1"
    "$LOGGER" "$msg"
    "$ECHO" "$msg" >> "$LOG_FILE"
  fi
}

#------------------------------------------------------------------------------#
# Function:    logDebug                                                        #
# Description: This functions prints debug messages into the log file.         #
#------------------------------------------------------------------------------#
logDebug()
{
  if [ "$LOG_LEVEL" -ge 4  ]; then
    local time_stamp
    time_stamp=$("$DATE" "+%F:%H:%M:%S%:z")
    local msg="$time_stamp: [DEBUG] $1"
    "$LOGGER" "$msg"
    "$ECHO" "$msg" >> "$LOG_FILE"
  fi
}

#------------------------------------------------------------------------------#
# Function:    assertCommandExecuted                                           #
# Description: Assert if the command invoked before the assertion finished     #
#              successfully. If not the whole installation of OpenIDM          #
#              is aborted with failure and the log message indicating issue.   #
# Parameters:  1 - String explanation why installation is aborted              #
# Exit code:   Aborts installation if error was detected.                      #
#------------------------------------------------------------------------------#
assertCommandExecuted() {
  local commandResult=$?

  if [[ $# -eq 0 || -z $1 ]]; then
    logError "No description argument supplied in assertCommandExecuted."
    terminateInstallation
  fi

  if [ -r "$COMMAND_OUT_LOG" ]; then
    local commandOutput=
    commandOutput=$("$CAT" "$COMMAND_OUT_LOG")
    if [ ! -z "$commandOutput" ];then
      logDebug "Command output is: $commandOutput"
      "$RM" -f "$COMMAND_OUT_LOG"
    fi 
  fi
  
  if [ "$commandResult" -ne 0 ]; then
    logError "$1"
    terminateInstallation
  fi
}

#------------------------------------------------------------------------------#
# Function:    assertFileExists                                                #
# Description: Assert that given file exists                                   #
# Parameters:  1 - Evaluated file                                              #
# Exit code:   Aborts installation if error was detected.                      #
#------------------------------------------------------------------------------#
assertFileExists() {
  if [[ $# -eq 0 || -z "$1" ]]; then
    logError "No file path supplied in assertFileExists."
    terminateInstallation
  fi

  logDebug "The file is: $1"
  if [ ! -r "$1" ]; then
    logError "File: $1 not found."
    terminateInstallation
  fi
}

#------------------------------------------------------------------------------#
# Function:    assertDecrypted                                                 #
# Description: Assert that the decrypting password was completed successfully. #
# Parameters:  1 - Evaluated variable holding decrypted value                  #
# Exit code:   Aborts installation if error was detected.                      #
#------------------------------------------------------------------------------#
assertDecrypted() {

  if [ $# -eq 0 ]; then
  logError "No password variable supplied in assertDecrypted."
    terminateInstallation
  fi

  if [ -z "$1" ]; then
    logError "Failed to decrypt $1."
    terminateInstallation
  fi
}

#------------------------------------------------------------------------------#
# Function:    assertPropertyExists                                            #
# Description: Assert that given property is set in global properties.         #
# Parameters:  1 - Evaluated property                                          #
# Exit code:   Aborts installation if error was detected.                      #
#------------------------------------------------------------------------------#
assertPropertyExists() {

  if [ $# -eq 0 ]; then

    logError "No property supplied in assertPropertyExists."
    terminateInstallation
  fi

  if [ -z "$1" ]; then
    logDebug "Property value is: $1"
    logError "Property does not exist."
    terminateInstallation
  fi
}
#------------------------------------------------------------------------------#
# Function:    changeOwnership                                                 #
# Description: Changes ownership of given files                                #
# Parameters:  1 - Directory/File path                                         #
# Exit code:   Aborts installation if error was detected.                      #
#------------------------------------------------------------------------------#
changeOwnership() {
  if [[ $# -eq 0 || -z "$1" ]]; then
    logError "No file path supplied in assertFileExists."
    terminateInstallation
  fi

  logDebug "The file is: $1"
  if [ ! -r "$1" ]; then
    logError "File: $1 not found."
    terminateInstallation
  fi
   
  "$CHOWN" -R "$OWNER_USER":"$OWNER_GROUP" "$1" 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to change ownership for: $1"
}

#------------------------------------------------------------------------------#
# Function:    decrypt                                                         #
# Description: Assert that given property is set in global properties.         #
# Parameters:  1 - Encrypted value                                             #
#              2 - Encryption key                                              #
#              3 - "Reference" to variable to hold return value                #
#------------------------------------------------------------------------------#
decrypt() {
  if [[ -z "$1" || "$1" = " " ]]; then
    logError "Syntax error! No argument supplied."
    terminateInstallation
  fi
  
  if [[ -z "$2" || "$2" = " " ]]; then
    logError "Syntax error! No argument supplied."
    terminateInstallation
  fi
  
  logDebug "Encrypted value: $1"
  logDebug "Encryption key: $2"

  eval "$3"="$("$ECHO" "$1" | "$OPENSSL" enc -a -d -aes-128-cbc -salt -kfile "$2")"
  assertCommandExecuted "Decryption failed."
}

#------------------------------------------------------------------------------#
# Function:    terminateInstallation                                           #
# Description: Kills the OpenIDM installation process.                         #
#------------------------------------------------------------------------------#
terminateInstallation() {
  logDebug "OpenIDM installation has been terminated."
  cleanup
  SERVEROUT_DIR="$OPENIDM_SAVE_LOG_DIR/server.out_${DATENOW}"
  "$MKDIR" -p "$OPENIDM_SAVE_LOG_DIR"
  "$MKDIR" -p "$SERVEROUT_DIR"
  "$CP" -f $LOG_DIR/server.out "$SERVEROUT_DIR"
  "$CP" -f $LOG_DIR/openidm-install* "$OPENIDM_SAVE_LOG_DIR"

  service openidm stop
  "$KILL" -s TERM "$OPENIDM_INSTALLATION_PID"
}

#------------------------------------------------------------------------------#
# Function:    cleanup                                                         #
# Description: Cleans temporary files, logs, configuration data                #
#------------------------------------------------------------------------------#
cleanup() {
  logInfo "Cleaning up temporary files."
  "$RM" -rf "$INST_TMP"
  #"$RM" -rf "$TMP_DIR"
  logInfo "Cleanup complete."
}

#------------------------------------------------------------------------------#
# Function:    checkIfPropertiesExist                                          #
# Description: Checks if properties below are not empty                        #
#------------------------------------------------------------------------------#
checkIfPropertiesExist(){

  assertPropertyExists "$POSTGRES_HOST"
  assertPropertyExists "$LDAP_ADMIN_CN"
  assertPropertyExists "$COM_INF_LDAP_ROOT_SUFFIX"
  assertPropertyExists "$COM_INF_LDAP_PORT"
  assertPropertyExists "$OPENDJ_LOCAL_HOST"
  assertPropertyExists "$OPENDJ_REMOTE_HOST"
  assertPropertyExists "$OPENDJ_HOSTNAME"
  assertPropertyExists "$UI_PRES_SERVER"
  assertPropertyExists "$OPENIDM_USER"
  assertPropertyExists "$OPENIDM_HOST"
  assertPropertyExists "$KEYSTORE_PWD"
  assertPropertyExists "$STORE_TYPE"
  assertPropertyExists "$KEYSTORE_NAME"
  assertPropertyExists "$TRUSTSTORE_NAME"
  assertPropertyExists "$LOCAL_HOSTNAME"
  assertPropertyExists "$KEY_VALIDITY_PERIOD"

}
