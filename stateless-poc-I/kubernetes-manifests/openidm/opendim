
#------------------------------------------------------------------------------#
# Function:    extractSource                                                   #
# Description: Extract the source tarball.                                     #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
extractSource()
{
  logInfo "Extracting OpenIDM source."

  "$CP" -rf "$TMP_ZIP_DIR" /ericsson 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to run:  $CP $TMP_ZIP_DIR /ericsson "

  "$RM" -rf "$OPENIDM_HOME" 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to run:  $RM -rf $OPENIDM_HOME"

  "$UNZIP" "$SOURCE_FILE" -d /ericsson 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to expand openidm.zip  while running: unzip openidm.zip "

  "$RM" "$SOURCE_FILE"

  logInfo "Successfuly extracted source"
  return 0
}


#------------------------------------------------------------------------------#
# Function:    setFilesAccessRights                                            #
# Description: Set access rights to OpenIDM directories                        #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
setFilesAccessRights() {
  #change group and ownership of OpenIDM home dir
  changeOwnership "$OPENIDM_HOME"

  #change group and ownwrship of openidm data dir
  changeOwnership "$TMP_DIR/openidm"

  logInfo "Successfuly changed openidm ownership"
  return 0
}

#------------------------------------------------------------------------------#
# Function:    setFilesAccessRights                                            #
# Description: Set access rights to OpenIDM directories                        #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
setLogrotatePermissions() {
   # /usr/sbin/semanage fcontext -a -t var_log_t /ericsson/tmp/openidm/conf/openidmlog
   # /sbin/restorecon -v /ericsson/tmp/openidm/conf/openidmlog

    logInfo "Successfully set logrotate(linux) permissions"
    return 0
}

#------------------------------------------------------------------------------#
# Function:    hardenOpenidm                                                   #
# Description: Disable Jetty's non-ssl port                                    #
#              Sets the permissions and ownership for OpenIDM file system      #
#              Removes: OSGI console                                           #
#                       Samples directory                                      #
#                       OpenIDM default UI                                     #
#                       Embedded Orient DB and its console                     #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
hardenOpenidm() {
  logInfo "Hardening OpenIDM"

  logInfo "Removeing OpenIDM's non secure port from jetty.xml"
  "$MV" -f "$OPENIDM_CONF_DIR/secure_jetty.xml" "$OPENIDM_CONF_DIR/jetty.xml" 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove OpenIDM's non secure port from $OPENIDM_CONF_DIR/secure_jetty.xml"

  logInfo "Changing permissions for Openidm directories and files."
  "$CHMOD" -R o-rwx "$OPENIDM_HOME" 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted " Failed to change permissions for Openidm directories and files"

  logInfo "Changing owernship for Openidm directories and files."
  changeOwnership "$OPENIDM_HOME"

  logInfo "Removing the samples directory."
  "$RM" -rf  "$OPENIDM_HOME/samples" 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove samples directory"

  logInfo "Removing the default UI directory."
  "$RM" -rf  $OPENIDM_HOME/ui 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove UI directory"

  logInfo "Removing the embedded Orient DB and its console."
  "$RM" -rf  $OPENIDM_BUNDLE_DIR/orientdb-server-1.7.10.jar \
          $OPENIDM_BUNDLE_DIR/orientdb-enterprise-1.7.10.jar \
          $OPENIDM_BUNDLE_DIR/orientdb-core-1.7.10.jar \
          $OPENIDM_BUNDLE_DIR/orientdb-client-1.7.10.jar \
          $OPENIDM_BUNDLE_DIR/orient-commons-1.7.10.jar \
          $OPENIDM_BUNDLE_DIR/orientdb-nativeos-1.7.10.jar \
          $OPENIDM_BUNDLE_DIR/openidm-repo-orientdb-4.5.0.jar \ 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove Orient DB and its console"

  logInfo "HardenOpenidm completed successfully"

  return 0
}

#------------------------------------------------------------------------------#
# Function:    copyConfigFiles                                                 #
# Description: Copy required files from temporary directory to OpenIDM         #
#              installation directory                                          #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
copyConfigFiles() {
  logInfo "Copying files"

  "$CP" -rf  ${TMP_DIR}/openidm/bundle/mysql-connector-java-*.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/bundle/mysql-connector-java-*-bin.jar  to  $OPENIDM_BUNDLE_DIR  "

  "$CP" -rf  ${TMP_DIR}/openidm/bundle/sessioninvalidation.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/bundle/sessioninvalidation.jar  to  $OPENIDM_BUNDLE_DIR  "

  "$MKDIR" -p ${TMP_DIR}/openidm/bundle/temp_dir
   assertCommandExecuted "Failed to create temp_dir directory"
  "$UNZIP"  ${TMP_DIR}/openidm/bundle/postgresql-9.4-1201-jdbc41.jar -d ${TMP_DIR}/openidm/bundle/temp_dir
   assertCommandExecuted "Failed to unzip postgresql-9.4-1201-jdbc41.jar"
  "$SED" -i '4d' /ericsson/tmp/openidm/bundle/temp_dir/META-INF/MANIFEST.MF
   assertCommandExecuted "Failed to modify META-INF/MANIFEST.MF file"
  "$JAR" cfm $OPENIDM_BUNDLE_DIR/postgre-modified-9.4-1201-jdbc41.jar /ericsson/tmp/openidm/bundle/temp_dir/META-INF/MANIFEST.MF -C /ericsson/tmp/openidm/bundle/temp_dir .
   assertCommandExecuted "Failed to create postgre-modified-9.4-1201-jdbc41.ja"
  "$RM" -fr ${TMP_DIR}/openidm/bundle/temp_dir
   assertCommandExecuted "Failed toremove temp_dir directory"
  "$CHMOD" 777 $OPENIDM_BUNDLE_DIR/postgre-modified-9.4-1201-jdbc41.jar
   assertCommandExecuted "Failed to change permissions for postgre-modified-9.4-1201-jdbc41.jar file"

  "$CP" -rf ${TMP_DIR}/openidm/conf/* $OPENIDM_CONF_DIR 2>$COMMAND_OUT_LOG

  assertCommandExecuted "Failed to copy   ${TMP_DIR}/openidm/conf/*  $OPENIDM_CONF_DIR "

  "$CP" -rf ${TMP_DIR}/openidm/script/* $OPENIDM_SCRIPT_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy   ${TMP_DIR}/openidm/script/*  $OPENIDM_SCRIPT_DIR "

  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-repo-jdbc-4.5.0.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy   ${TMP_DIR}/openidm/patches/openidm-repo-jdbc-4.5.0.jar  $OPENIDM_BUNDLE_DIR "

  "$RM" -f ${OPENIDM_BUNDLE_DIR}/openidm-workflow-activiti-*.jar 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove old openidm-workflow-activity jar in $OPENIDM_BUNDLE_DIR to apply patch Sec-201705"

  "$UNZIP" -o ${TMP_DIR}/openidm/patches/OPENIDM-sec-201705-v450.zip -d $OPENIDM_HOME 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to unzip  ${TMP_DIR}/openidm/patches/OPENIDM-sec-201705-v450.zip in $OPENIDM_HOME "

  "$RM" -rf ${OPENIDM_HOME}/felix-cache/* 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to purge $OPENIDM_HOME/felix-cache/ folder to apply patch Sec-201705"

  #/sbin/restorecon $OPENIDM_CONF_DIR/openidmlog 2>"$COMMAND_OUT_LOG"
  #assertCommandExecuted "Failed to set correct SELinux context for $OPENIDM_CONF_DIR/openidmlog file"

  #"$MV" -f $OPENIDM_CONF_DIR/openidmLogRotate $CRON_HOURLY_DIR/ 2>"$COMMAND_OUT_LOG"
  #assertCommandExecuted "Failed to move $OPENIDM_CONF_DIR/openidmLogRotate $CRON_HOURLY_DIR "
  
  #logInfo "$CRON_SVC restart"
  #"$CRON_SVC" restart
  assertCommandExecuted "Failed to restart cron job "

  logInfo "Successfully copied files"
  return 0
}

#------------------------------------------------------------------------------#
# Function:    cleanupRedundantFiles                                           #
# Description: Femove redundant files from temporary directory                 #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
cleanupRedundantFiles() {
  logInfo "Temporary files cleanup."

  "$RM" -rf  $OPENIDM_CONF_DIR/repo.orientdb.json 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove  $OPENIDM_CONF_DIR/repo.orientdb.json"

  "$RM" -rf  $OPENIDM_HOME/startup.bat 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove $OPENIDM_HOME/startup.bat"

  logInfo "Files cleanup successfully finished."
  return 0
}

#------------------------------------------------------------------------------#
# Function:    copyFilesToLocal                                                #
# Description: Function to copy files from SFS to local if they are different  #
#              Function requires two arguments:                                #
#               1) file which we want to copy                                  #
#               2) directory where we want to copy files                       #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
# Function to copy files from SFS to local if they are different
copyFilesToLocal() {
  FILE_FROM="${1}"
  DIR_TO="${2}"

# Create local directory for SFS data
  mkdir -p ${DIR_TO};

# Copy file from SFS to local if exist
  if [ -f "${FILE_FROM}" ]; then
    cp -f "${FILE_FROM}" "${DIR_TO}"
  else
    logInfo "Cannot find file ${FILE_FROM}"
  fi
}

#------------------------------------------------------------------------------#
# Function:    decryptPasswords                                                 #
# Description: Updates various passwords like:                                 #
#               1) LDAP-admin user password                                    #
#               2) mysql root user password                                    #
#               3) openidm-admin user password                                 #
#               4) security-admin user password                                #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
decryptPasswords() {
  local opendjPasskey=/ericsson/tor/data/idenmgmt/opendj_passkey
  assertFileExists "${opendjPasskey}"
  local mysqlPasskey=/ericsson/tor/data/idenmgmt/idmmysql_passkey
  assertFileExists "${mysqlPasskey}"
  local openidmPasskey=/ericsson/tor/data/idenmgmt/openidm_passkey
  assertFileExists "${openidmPasskey}"
  local adminPasskey=/ericsson/tor/data/idenmgmt/secadmin_passkey
  assertFileExists "${adminPasskey}"

  logInfo "Updating passwords."

  logInfo "Decrypting Directory Manager password"
  assertPropertyExists $LDAP_ADMIN_PASSWORD
  decrypt $LDAP_ADMIN_PASSWORD $opendjPasskey DM_PWD
  assertDecrypted "$DM_PWD"

  logInfo "Decrypting Security Admin password"
  assertPropertyExists "$default_security_admin_password"
  decrypt $default_security_admin_password $adminPasskey SECURITY_ADMIN_PWD
  assertDecrypted "$SECURITY_ADMIN_PWD"

  logInfo "Decrypting MySQL Admin password"
  assertPropertyExists "$idm_mysql_admin_password"
  decrypt $idm_mysql_admin_password $mysqlPasskey MYSQL_OPENIDM_PWD
  assertDecrypted "$MYSQL_OPENIDM_PWD"

  logInfo "Decrypting default OpenIDM Admin password"
  assertPropertyExists "$openidm_admin_password"
  decrypt $openidm_admin_password $openidmPasskey OPENIDM_PWD
  assertDecrypted "$OPENIDM_PWD"

  logInfo "Updating passwords finished successfully."
  return 0
}

#------------------------------------------------------------------------------#
# Function:    updatePasswordsInMySQL                                          #
# Description: Updates passwords in MySQL database:                            #
#              1) openidm-admin user password                                  #
#              2) mysql root user password                                     #
#              3) openidm user password                                        #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
updatePasswordsInMySQL() {

   logInfo "Updating MySQL passwords"

   assertPropertyExists "$MYSQL_OPENIDM_PWD"
   assertPropertyExists "$OPENIDM_BOOT_PROPERTIES_FILE"

  "$SED" -e "s|security/keystore.jceks|${KEYSTORE_NAME}|g" $OPENIDM_BOOT_PROPERTIES_FILE  > $INST_TMP/boot.properties
  "$CP" $INST_TMP/boot.properties $OPENIDM_BOOT_PROPERTIES_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace boot.properties for keystore location"

  "$SED" -e "s|security/truststore|${TRUSTSTORE_NAME}|g" $OPENIDM_BOOT_PROPERTIES_FILE  > $INST_TMP/boot.properties
  "$CP" $INST_TMP/boot.properties $OPENIDM_BOOT_PROPERTIES_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace boot.properties for truststore location"
  "$RM" -f $INST_TMP/boot.properties
  
  "$SH" $OPENIDM_HOME/cli.sh encrypt $OPENIDM_PWD > $INST_TMP/encrypted_openidm_pwd 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to encrypt $OPENIDM_USER password"

  logInfo "Reading $OPENIDM_USER encrypted password"
  local ENCRYPTED_PWD=`sed -n '/BEGIN ENCRYPTED/,/END ENCRYPTED/p' \
                               $INST_TMP/encrypted_openidm_pwd | grep -v \
                               "ENCRYPTED VALUE" | tr -d '\040\011\012\015'`
  assertCommandExecuted "Failed to read $OPENIDM_USER encrypted password"

  rm -f $INST_TMP/encrypted_openidm_pwd
  assertCommandExecuted "Failed to remove temporary file with $OPENIDM_USER encrypted password"

  logInfo "Creating temporary SQL script updating encrypted password"
  local TMP_SQL_SCRIPT=$INST_TMP/localPassScr.sql
  local SQL_OUT=$INST_TMP/updatePasswd.out.$$

    cat << EOF > $TMP_SQL_SCRIPT
UPDATE openidm.internaluser SET pwd='$ENCRYPTED_PWD' \
WHERE objectid='$OPENIDM_USER';
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_OPENIDM_PWD') \
WHERE User='$MYSQL_OPENIDM_USER';
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_OPENIDM_PWD') \
WHERE User='$MYSQL_ROOT_USER';
FLUSH PRIVILEGES;
quit
EOF
  assertCommandExecuted "Failed to create temporary SQL script: $TMP_SQL_SCRIPT"

  logInfo "Updating $OPENIDM_USER encrypted password in MySQL"
  $( $MYSQL --user=$MYSQL_ROOT_USER --password=$MYSQL_OPENIDM_PWD \
            --host=$MYSQL_HOST < $TMP_SQL_SCRIPT > $SQL_OUT 2>&1 )
  assertCommandExecuted "Failed to execute the temporary SQL script to update MySQL passwords. Refer to ${SQL_OUT} for more details."

 "$RM" -f $TMP_SQL_SCRIPT

  logInfo "MySQL passwords have been updated successfully"
  return 0
}


#------------------------------------------------------------------------------#
# Function:    LivesyncIssueCleanMySQLConfig                                   #
# Description: In case of missing configurationni MySQL Livesync options       #
#              clean tables: configobjects, schedulerobjects and restart       #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
livesyncIssueCleanMySQLConfig() {

  logInfo "Cleaning MySQL config if <<trigger-activeSynchroniser_systemLdapAccount>> does not exist"

  assertPropertyExists "$MYSQL_OPENIDM_PWD"

  logInfo "Checking if configuration contains <<trigger-activeSynchroniser_systemLdapAccount>>"
  local TMP_SCHEDULER_CHECK_OUT=$INST_TMP/checkConfig.out
  $MYSQL --user=$MYSQL_ROOT_USER --password=$MYSQL_OPENIDM_PWD --host=$MYSQL_HOST \
         --silent --execute='SELECT count(*) FROM openidm.schedulerobjects WHERE objectid LIKE "%trigger-activeSynchroniser_systemLdapAccount%"' > $TMP_SCHEDULER_CHECK_OUT 2>&1
  assertCommandExecuted "Failed to execute SQL check script. Refer to ${TMP_SCHEDULER_CHECK_OUT} for more details."

  if [ `tail -n 1 $TMP_SCHEDULER_CHECK_OUT` == '0' ]; then
    logInfo "Missing entries found - cleaning"
    local TMP_SQL_SCRIPT=$INST_TMP/cleanConfig.sql

    cat << EOF > $TMP_SQL_SCRIPT
DELETE FROM openidm.configobjects;
DELETE FROM openidm.schedulerobjects;
quit
EOF
    assertCommandExecuted "Failed to create temporary SQL script: $TMP_SQL_SCRIPT"

    $MYSQL --user=$MYSQL_ROOT_USER --password=$MYSQL_OPENIDM_PWD \
            --host=$MYSQL_HOST < $TMP_SQL_SCRIPT
    assertCommandExecuted "Failed to execute the temporary SQL script to clean configuration."

    "$RM" -f $TMP_SQL_SCRIPT
     logInfo "MySQL configuration cleaned"
  fi

  return 0
}


#------------------------------------------------------------------------------#
# Function:    updateConfigFiles                                               #
# Description: Updates OpenIDM configuration files                             #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
updateConfigFiles() {

  logInfo "Updating OpenIDM config files with environment specific data."

  checkIfPropertiesExist
  assertPropertyExists "$MYSQL_OPENIDM_PWD"

  AUTHENTICATION_JSON=${OPENIDM_CONF_DIR}/authentication.json
  logInfo "Updating: $AUTHENTICATION_JSON"
  "$SED" -e "s/UI_PRES_SERVER/$UI_PRES_SERVER/g" $AUTHENTICATION_JSON > $INST_TMP/authentication.json
  assertCommandExecuted "Failed to update: $AUTHENTICATION_JSON"
  "$CP" $INST_TMP/authentication.json $AUTHENTICATION_JSON 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $AUTHENTICATION_JSON"

  DATASOURCE_JDBC_DEFAULT_JSON=${OPENIDM_CONF_DIR}/datasource.jdbc-default.json
  logInfo "Updating: $DATASOURCE_JDBC_DEFAULT_JSON"
  "$SED" -e "s/MYSQL_HOST/${MYSQL_HOST}/g" -e "s/MYSQL_OPENIDM_PASSWORD/${MYSQL_OPENIDM_PWD}/g" $DATASOURCE_JDBC_DEFAULT_JSON > $INST_TMP/datasource.jdbc-default.json
  assertCommandExecuted "Failed to update: $DATASOURCE_JDBC_DEFAULT_JSON"
  "$CP" $INST_TMP/datasource.jdbc-default.json $DATASOURCE_JDBC_DEFAULT_JSON 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $DATASOURCE_JDBC_DEFAULT_JSON"


  OPENICF_LDAP_JSON=${OPENIDM_CONF_DIR}/provisioner.openicf-ldap.json
  logInfo "Updating: $OPENICF_LDAP_JSON"
  "$SED" -e "s/DM_DN/$LDAP_ADMIN_CN/g" -e "s/BASE_DN/$COM_INF_LDAP_ROOT_SUFFIX/g" -e "s/DM_PWD/$DM_PWD/g" \
  -e "s/LDAP_PORT/${COM_INF_LDAP_PORT}/g" -e "s/OPENDJ_LOCAL_HOSTNAME/${OPENDJ_LOCAL_HOST}/g" \
  -e "s/OPENDJ_REMOTE_HOSTNAME/${OPENDJ_REMOTE_HOST}/g" $OPENICF_LDAP_JSON > $INST_TMP/provisioner.openicf-ldap.json
  assertCommandExecuted "Failed to update: $OPENICF_LDAP_JSON"
  "$CP" $INST_TMP/provisioner.openicf-ldap.json $OPENICF_LDAP_JSON 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $OPENICF_LDAP_JSON"

  OPENICF_LDAP_PASSWORD_POLICY_JSON=${OPENIDM_CONF_DIR}/provisioner.openicf-passwordPolicyLdap.json
  logInfo "Updating: $OPENICF_LDAP_PASSWORD_POLICY_JSON"
  "$SED" -e "s/DM_DN/$LDAP_ADMIN_CN/g" -e "s/BASE_DN/$COM_INF_LDAP_ROOT_SUFFIX/g" -e "s/DM_PWD/$DM_PWD/g" \
  -e "s/LDAP_PORT/${COM_INF_LDAP_PORT}/g" -e "s/OPENDJ_LOCAL_HOSTNAME/${OPENDJ_LOCAL_HOST}/g" \
  -e "s/OPENDJ_REMOTE_HOSTNAME/${OPENDJ_REMOTE_HOST}/g" $OPENICF_LDAP_PASSWORD_POLICY_JSON > $INST_TMP/provisioner.openicf-passwordPolicyLdap.json
  assertCommandExecuted "Failed to update: $OPENICF_LDAP_PASSWORD_POLICY_JSON"
  "$CP" $INST_TMP/provisioner.openicf-passwordPolicyLdap.json $OPENICF_LDAP_PASSWORD_POLICY_JSON 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $OPENICF_LDAP_PASSWORD_POLICY_JSON"

  LDAP_SYNC_JS=${OPENIDM_SCRIPT_DIR}/ldapUserSync.js
  logInfo "Updating: $LDAP_SYNC_JS"
  "$SED" -e "s/BASE_DN/$COM_INF_LDAP_ROOT_SUFFIX/g" $LDAP_SYNC_JS > $INST_TMP/ldapUserSync.js
  assertCommandExecuted "Failed to update: $LDAP_SYNC_JS"
  "$CP" $INST_TMP/ldapUserSync.js $LDAP_SYNC_JS 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $LDAP_SYNC_JS"

  LDAP_SYNC_GROUP_JS=${OPENIDM_SCRIPT_DIR}/ldapGroupSync.js
  logInfo "Updating: $LDAP_SYNC_GROUP_JS"
  "$SED" -e "s/BASE_DN/$COM_INF_LDAP_ROOT_SUFFIX/g" $LDAP_SYNC_GROUP_JS > $INST_TMP/ldapGroupSync.js
  assertCommandExecuted "Failed to update: $LDAP_SYNC_GROUP_JS"
  "$CP" $INST_TMP/ldapGroupSync.js $LDAP_SYNC_GROUP_JS 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $LDAP_SYNC_GROUP_JS"

  POST_USER_UPDATE_JS=${OPENIDM_SCRIPT_DIR}/postUserUpdate.js
  logInfo "Updating: $POST_USER_UPDATE_JS"
  "$SED" -e "s/BASE_DN/$COM_INF_LDAP_ROOT_SUFFIX/g" $POST_USER_UPDATE_JS >$INST_TMP/postUserUpdate.js
  assertCommandExecuted "Failed to update: $POST_USER_UPDATE_JS"
  "$CP" $INST_TMP/postUserUpdate.js $POST_USER_UPDATE_JS 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $POST_USER_UPDATE_JS"

  POST_USER_CREATE_JS=${OPENIDM_SCRIPT_DIR}/postUserCreate.js
  logInfo "Updating: $POST_USER_CREATE_JS"
  "$SED" -e "s/BASE_DN/$COM_INF_LDAP_ROOT_SUFFIX/g" $POST_USER_CREATE_JS >$INST_TMP/postUserCreate.js
  assertCommandExecuted "Failed to update: $POST_USER_CREATE_JS"
  "$CP" $INST_TMP/postUserCreate.js $POST_USER_CREATE_JS 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $POST_USER_CREATE_JS"

  LDAP_PASSWORD_POLICY_SYNC_CREATE_JS=${OPENIDM_SCRIPT_DIR}/ldapPasswordPolicySync.js
  logInfo "Updating: $LDAP_PASSWORD_POLICY_SYNC_CREATE_JS"
  "$SED" -e "s/BASE_DN/$COM_INF_LDAP_ROOT_SUFFIX/g" $LDAP_PASSWORD_POLICY_SYNC_CREATE_JS >$INST_TMP/ldapPasswordPolicySync.js
  assertCommandExecuted "Failed to update: $LDAP_PASSWORD_POLICY_SYNC_CREATE_JS"
  "$CP" $INST_TMP/ldapPasswordPolicySync.js $LDAP_PASSWORD_POLICY_SYNC_CREATE_JS 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $LDAP_PASSWORD_POLICY_SYNC_CREATE_JS"

  SHUTDOWN_SH=${OPENIDM_HOME}/shutdown.sh
  logInfo "Fixing forgerock pkill bug: ${SHUTDOWN_SH}"
  "$SED" -e "s%pkill[[:space:]]-P%kill%g" $SHUTDOWN_SH > $INST_TMP/shutdown.sh
  assertCommandExecuted "Failed to update: $SHUTDOWN_SH"
  "$CHOWN" --reference=${SHUTDOWN_SH} $INST_TMP/shutdown.sh
  "$CHMOD" --reference=${SHUTDOWN_SH} $INST_TMP/shutdown.sh
  "$CP" -f $INST_TMP/shutdown.sh $SHUTDOWN_SH 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $SHUTDOWN_SH"
  
  SYSTEM_PROPS=${OPENIDM_CONF_DIR}/system.properties
  logInfo "Updating: $SYSTEM_PROPS"
  "$SED" -e "s%OPENIDM_HOME%${OPENIDM_HOME}%g" $SYSTEM_PROPS > $INST_TMP/system.properties
  assertCommandExecuted "Failed to update: $SYSTEM_PROPS"
  "$CP" $INST_TMP/system.properties $SYSTEM_PROPS 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to update: $SYSTEM_PROPS"

  logInfo "Updating OpenIDM config files finished successfully."
  return 0
}

#------------------------------------------------------------------------------#
# Function:    obfuscateKeystorePassword                                       #
# Description: Obfuscate the Default Keystore Password                         #
# Parameters:  nothing                                                         #
#------------------------------------------------------------------------------#
obfuscateKeystorePassword() {

  assertPropertyExists "$OPENIDM_PWD"
  assertPropertyExists "$OPENIDM_BOOT_PROPERTIES_FILE"

  local obfKeystorePwd=`"$JAVA" -jar $OPENIDM_HOME/bundle/openidm-crypto-4.5.0.jar $OPENIDM_PWD 2>&1 | "$GREP" "OBF:"`
  assertPropertyExists "$obfKeystorePwd"

  logInfo "Updating boot.properties with the obfuscated keystore password"
  "$SED" -e "s/openidm.keystore.password=changeit/openidm.keystore.password=$obfKeystorePwd/g" -e "s/openidm.truststore.password=changeit/openidm.truststore.password=$obfKeystorePwd/g" \
      -e "s/openidm.port.http=8080/openidm.port.http=8085/g"  -e "s/openidm.port.https=8443/openidm.port.https=8445/g" -e "s/openidm.port.mutualauth=8444/openidm.port.mutualauth=8446/g" $OPENIDM_BOOT_PROPERTIES_FILE > $INST_TMP/boot.properties
  assertCommandExecuted "Failed to modify boot.properties file"

  "$CP" $INST_TMP/boot.properties $OPENIDM_BOOT_PROPERTIES_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace boot.properties"
  "$RM" -f $INST_TMP/boot.properties
}

#------------------------------------------------------------------------------#
# Function:    setOpenIdmKeystore                                              #
# Description: Secure OpenIDM keystore openidm admin password from SED file.   #
#              Replace the default symmetric key in the keystore.              #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
setOpenIdmKeyStorePassword() {
  logInfo "Setting up OpenIDM keystore"

 checkIfPropertiesExist

  OPENIDM_SYM_KEY_DEFAULT="openidm-sym-default"

  "$KEYTOOL" -storepasswd -keystore $KEYSTORE_NAME -storetype $STORE_TYPE \
          -storepass $KEYSTORE_PWD -new $OPENIDM_PWD 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to change default OpenIDM keystore password"

  "$KEYTOOL" -storepasswd -keystore $TRUSTSTORE_NAME \
          -storepass $KEYSTORE_PWD -new $OPENIDM_PWD 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to change default OpenIDM truststore password"

  TMP_SYM_KEYSTORE=/ericsson/tor/data/idenmgmt/openidm-sym-keystore.jceks

  if [ ! -f $TMP_SYM_KEYSTORE ]; then
    ${KEYTOOL} -genseckey -alias $OPENIDM_SYM_KEY_DEFAULT -keystore $TMP_SYM_KEYSTORE \
          -storepass $OPENIDM_PWD -keypass $OPENIDM_PWD -storetype $STORE_TYPE \
          -keyalg $SYM_KEY_ALG -keysize $SYM_KEY_SIZE
  fi

  #import the openidm symmetric key from openidm-sym-keystore
  "$KEYTOOL" -importkeystore -srckeystore $TMP_SYM_KEYSTORE \
          -srcstoretype $STORE_TYPE -srcstorepass $OPENIDM_PWD \
          -destkeystore $KEYSTORE_NAME -deststoretype $STORE_TYPE \
          -deststorepass $OPENIDM_PWD -srcalias $OPENIDM_SYM_KEY_DEFAULT \
          -destalias $OPENIDM_SYM_KEY_DEFAULT -srckeypass $OPENIDM_PWD \
          -destkeypass $OPENIDM_PWD 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import the openidm symmetric key"

  obfuscateKeystorePassword

  logInfo "OpenIDM keystore has been set up successfully"
  return 0
}
#------------------------------------------------------------------------------#
# Function:    configOpenidmCertificates                                       #
# Description: Creates certificates for openidm, sign them with the rootCA     #
#              cert and imports all of them into openidm keystore and          #
#              truststore                                                      #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
configOpenidmCertificates() {
  logInfo "Configuring certificates."

  checkIfPropertiesExist
  assertPropertyExists "$OPENIDM_PWD"

  openidm_alias1=$LOCAL_HOSTNAME
  openidm_alias2=$OPENIDM_HOST
  openidm_alias3=$OPENIDM_HOST

 "$SED" -e "s/OPENIDMHOST1/$openidm_alias1/g" -e "s/OPENIDMHOST2/$openidm_alias2/g" \
 -e "s/OPENIDMHOST3/$openidm_alias3/g" $OPENIDM_SSL_EXT_FILE > $INST_TMP/openidm_ssl_ext
  assertCommandExecuted "Failed to update $OPENIDM_SSL_EXT_FILE"

  "$CP" $INST_TMP/openidm_ssl_ext $OPENIDM_SSL_EXT_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace $OPENIDM_SSL_EXT_FILE"
  "$RM" -f $SSL_EXT_TEMP_FILE

 logInfo "Import the rootCA into openidm's keystore."
  "$KEYTOOL" -import -no-prompt -trustcacerts -alias rootCA -keystore $KEYSTORE_NAME -storetype $STORE_TYPE \
  -storepass $OPENIDM_PWD -file $ROOTCA_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import the Root CA into OpenIDM's keystore"

  logInfo "Delete the truststore to cleanup all default trusted certs."
  "$RM" -rf $TRUSTSTORE_NAME
  assertCommandExecuted "Failed to delete the truststore to cleanup all default trusted certs"

  logInfo "Importing the rootCA into openidm's truststore."
  "$KEYTOOL" -import -trustcacerts -no-prompt -alias rootCA -keystore $TRUSTSTORE_NAME -storepass $OPENIDM_PWD -file $ROOTCA_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import the Root CA into OpenIDM's truststore"


  # Operations on openidm-local-openidm-forgerock-org certificate
  logInfo "Creating, signing and exporting Openidm certificate openidm-local-openidm-forgerock-org."
  "$KEYTOOL" -genkey -alias openidm-local-openidm-forgerock-org -validity $KEY_VALIDITY_PERIOD -keyalg "RSA" -keysize 2048 -dname "CN=$OPENIDM_HOST" -keystore $KEYSTORE_NAME -keypass "$OPENIDM_PWD" -storepass "$OPENIDM_PWD" -storetype $STORE_TYPE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to generate Openidm keypair for certificate openidm-local-openidm-forgerock-org "

  logInfo "Creating a CSR for openidm-local-openidm-forgerock-org"
  "$KEYTOOL" -certreq -v -alias openidm-local-openidm-forgerock-org -keystore $KEYSTORE_NAME -storepass "$OPENIDM_PWD" -storetype $STORE_TYPE -file "${TMP_DIR}/openidm/config/openidm-local-openidm-forgerock-org.csr" 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to create a CSR for Openidm's certificate openidm-local-openidm-forgerock-org"

  logInfo "Signing the CSR using the Root CA."
  "$OPENSSL" x509 -req -in ${TMP_DIR}/openidm/config/openidm-local-openidm-forgerock-org.csr -CA $ROOTCA_FILE -CAkey $ROOTCA_KEY_FILE -CAcreateserial -out ${TMP_DIR}/openidm/config/openidm-local-openidm-forgerock-org.pem -days $KEY_VALIDITY_PERIOD 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to sign a CSR for Openidm's certificate openidm-local-openidm-forgerock-org"

  logInfo "Importing openidm certificate for openidm-local-openidm-forgerock-org into the keystore."
  "$KEYTOOL" -import -no-prompt -trustcacerts -alias openidm-local-openidm-forgerock-org -keystore $KEYSTORE_NAME -storepass $OPENIDM_PWD -storetype $STORE_TYPE -file ${TMP_DIR}/openidm/config/openidm-local-openidm-forgerock-org.pem 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import Openidm's certificate openidm-local-openidm-forgerock-org into the keystore"

  logInfo "Importing openidm's certificate into openidm's trustore."
  "$KEYTOOL" -import -no-prompt -trustcacerts -alias openidm-local-openidm-forgerock-org -keystore $TRUSTSTORE_NAME -storepass $OPENIDM_PWD -file ${TMP_DIR}/openidm/config/openidm-local-openidm-forgerock-org.pem 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import Openidm's certificate openidm-local-openidm-forgerock-org into the truststore"

  # Operations on openidm-localhost certificate
  logInfo "Creating, signing and exporting Openidm certificate openidm-localhost."
  "$KEYTOOL" -genkey -alias openidm-localhost -validity $KEY_VALIDITY_PERIOD -keyalg "RSA" -keysize 2048 -dname "CN=$OPENIDM_HOST" -keystore $KEYSTORE_NAME -keypass "$OPENIDM_PWD" -storepass "$OPENIDM_PWD" -storetype $STORE_TYPE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to generate Openidm keypair for certificate openidm-localhost"

  logInfo "Creating a CSR for openidm-localhost."
  "$KEYTOOL" -certreq -v -alias openidm-localhost -keystore $KEYSTORE_NAME -storepass "$OPENIDM_PWD" -storetype $STORE_TYPE -file "${TMP_DIR}/openidm/config/openidm-localhost.csr" 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to create a CSR for Openidm's certificate openidm-localhost"

  logInfo "Signing the CSR using the Root CA."
  "$OPENSSL" x509 -req -in ${TMP_DIR}/openidm/config/openidm-localhost.csr -CA $ROOTCA_FILE -CAkey $ROOTCA_KEY_FILE -CAcreateserial -out ${TMP_DIR}/openidm/config/openidm-localhost.pem -days $KEY_VALIDITY_PERIOD -extensions v3_req -extfile $OPENIDM_SSL_EXT_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to sign a CSR for Openidm's certificate openidm-localhost"

  logInfo "Importing openidm certificate for openidm-localhost into the keystore."
  "$KEYTOOL" -import -no-prompt -trustcacerts -alias openidm-localhost -keystore $KEYSTORE_NAME -storepass $OPENIDM_PWD -storetype $STORE_TYPE -file ${TMP_DIR}/openidm/config/openidm-localhost.pem 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import Openidm's certificat openidm-localhost into the keystore"

  logInfo "Importing openidm's certificate into openidm's trustore."
  "$KEYTOOL" -import -no-prompt -trustcacerts -alias openidm-localhost -keystore $TRUSTSTORE_NAME -storepass $OPENIDM_PWD -file ${TMP_DIR}/openidm/config/openidm-localhost.pem 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import Openidm's certificate openidm-localhost into the truststore"

  # remove the csr files
  rm -f ${TMP_DIR}/openidm/config/*.csr

  logInfo "Import apache server certificate into openidm truststore."
  "$KEYTOOL" -import -trustcacerts  -no-prompt -alias ssoapacheserver -keystore $TRUSTSTORE_NAME -storepass $OPENIDM_PWD -file $APACHE_SERVER_CERT_FILE 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to import the certificate of Apache server certificate into OpenIDM's truststore"

  logInfo "Configuring certificates completed successfully."
  return 0
}

#------------------------------------------------------------------------------#
# Function:    updateMysqlSchema                                               #
# Description: Drop and create Mysql schema for OpenIDM 4.5 if needed                  #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
updateMysqlSchema() {
  logInfo "Creating MySQL schema after drop if neccessary"

  assertPropertyExists "$MYSQL_OPENIDM_PWD"

  logInfo "Checking if schema needs re-creation"
  query=$(($MYSQL --user=$MYSQL_ROOT_USER --password=$MYSQL_OPENIDM_PWD --host=$MYSQL_HOST --execute='SELECT * FROM openidm.internalrole limit 1') 2>&1)
#   assertCommandExecuted "Failed to execute SQL check script. Output: ${query}"

  if [[ $query =~ .*ERROR.* ]] && [[ $query =~ .*openidm\.internalrole\'.doesn\'t.exist ]]; then
   logInfo "Drop and create schema for OpenIDM 4.5"
   local TMP_SCHEMA_UPLIFT=/tmp/openidmDropCreate.sql
   query=$((${MYSQL} --user=${MYSQL_ROOT_USER} --password=${MYSQL_OPENIDM_PWD} --host=${MYSQL_HOST} ${MYSQL_OPENIDM_DATABASE} < ${MYSQL_SCHEMA_UPDATE_SQL}) 2>&1 | tee $TMP_SCHEMA_UPLIFT)
   assertCommandExecuted "Failed to drop and create schema for MySQL. Refer to ${TMP_SCHEMA_UPLIFT} for more details."
   logInfo "Schema update completed"
#   "$RM" -f $TMP_SCHEMA_UPLIFT
  else
   logInfo "Schema is already updated for OpenIDM 4.5"
  fi
  return 0
}

#------------------------------------------------------------------------------#
# Function:    createConfiguredFile                                            #
# Description: Create .openidm.configured file used for healthcheck            #
# Parameters:  nothing                                                         #
# Returns:     nothing                                                         #
#------------------------------------------------------------------------------#
createConfiguredFile() {
  "$TOUCH" "$OPENIDM_CONFIGURED_FILE"
}

