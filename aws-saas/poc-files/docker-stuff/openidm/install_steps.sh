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
# Function:    setLogrotatePermissions                                         #
# Description: Set permissions on logrotate                                    #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
setLogrotatePermissions() {
#    /usr/sbin/semanage fcontext -a -t var_log_t /ericsson/tmp/openidm/conf/openidmlog
#    /sbin/restorecon -v /ericsson/tmp/openidm/conf/openidmlog

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
          $OPENIDM_BUNDLE_DIR/openidm-repo-orientdb-4.5.1.jar \ 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove Orient DB and its console"

  logInfo "HardenOpenidm completed successfully"

  return 0
}

addBCProviderToJavaSecurity() {

	JAVA_LATEST=/usr/java/latest

	if [ $EUID -ne 0 ]; then
  		logInfo "Script can be run by the root user only"
 		return 1 
	fi

	if [ -e $JAVA_HOME/jre/lib/security/java.security ]; then
  		JAVA_SECURITY_FILE=$JAVA_HOME/jre/lib/security/java.security
  		logInfo "found $JAVA_HOME/jre/lib/security/java.security"
	elif [ -e $JAVA_LATEST/jre/lib/security/java.security ]; then
  		JAVA_SECURITY_FILE=$JAVA_LATEST/jre/lib/security/java.security
  		logInfo "found $JAVA_LATEST/jre/lib/security/java.security"
	else
  		logInfo "java.security not found"
  		return 1
	fi
	FIND_BC=$($GREP -c "=org.bouncycastle.jce.provider.BouncyCastleProvider" /$JAVA_SECURITY_FILE)
	if [ $FIND_BC -ne 0 ]; then
  		logInfo "BC provider already defined"
  		return 0
	fi

	LAST_N=$($GREP -c  "^security.provider.*=" /$JAVA_SECURITY_FILE)
	N_ROW=$LAST_N
	BC_NUM=`expr $N_ROW + 1`

	LAST_ROW=$($GREP "^security.provider.$N_ROW=" /$JAVA_SECURITY_FILE)
	BC_PROV=$(echo "security.provider."$BC_NUM"=org.bouncycastle.jce.provider.BouncyCastleProvider")

	"$SED" -e "s|$LAST_ROW|$LAST_ROW\n$BC_PROV|g" /$JAVA_SECURITY_FILE > /ericsson/tmp/java.security
	if [ $? -ne 0 ]; then
		logInfo "SED failed"
		return 1
	fi
	
	"$CP" /ericsson/tmp/java.security  "$JAVA_SECURITY_FILE"
	if [ $? -ne 0 ]; then
		logInfo "CP failed"
		return 1
	fi
	
	"$RM" -f /ericsson/tmp/java.security
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

  "$CP" -rf  ${TMP_DIR}/openidm/bundle/sessioninvalidation.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/bundle/sessioninvalidation.jar  to  $OPENIDM_BUNDLE_DIR  "

  "$CP" -rf  ${TMP_DIR}/openidm/bundle/iden-mgmt-openidm-notify-user-update-roles.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/bundle/iden-mgmt-openidm-notify-user-update-roles  to  $OPENIDM_BUNDLE_DIR  "
   
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

# START patch for TORF-265237 #
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-api-servlet-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-api-servlet-4.5.1.jar $OPENIDM_BUNDLE_DIR "
  
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-audit-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-audit-4.5.1.jar $OPENIDM_BUNDLE_DIR "
  
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-infoservice-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-infoservice-4.5.1.jar $OPENIDM_BUNDLE_DIR "
  
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-router-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-router-4.5.1.jar $OPENIDM_BUNDLE_DIR "
  
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-selfservice-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-selfservice-4.5.1.jar $OPENIDM_BUNDLE_DIR "
  
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-system-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-system-4.5.1.jar $OPENIDM_BUNDLE_DIR "
  
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-util-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-util-4.5.1.jar $OPENIDM_BUNDLE_DIR "
# END patch for TORF-265237 # 
# START patch for TORF-271025 #
  "$CP" -rf ${TMP_DIR}/openidm/patches/openidm-repo-jdbc-4.5.1.jar $OPENIDM_BUNDLE_DIR 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to copy ${TMP_DIR}/openidm/patches/openidm-repo-jdbc-4.5.1.jar $OPENIDM_BUNDLE_DIR "

# END patch for TORF-271025 # 
  "$RM" -f ${OPENIDM_BUNDLE_DIR}/openidm-workflow-activiti-*.jar 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to remove old openidm-workflow-activity jar in $OPENIDM_BUNDLE_DIR to apply patch Sec-201705"

  "$RM" -rf ${OPENIDM_HOME}/felix-cache/* 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to purge $OPENIDM_HOME/felix-cache/ folder to apply patch Sec-201705"

 # /sbin/restorecon $OPENIDM_CONF_DIR/openidmlog 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to set correct SELinux context for $OPENIDM_CONF_DIR/openidmlog file"

 # "$MV" -f $OPENIDM_CONF_DIR/openidmLogRotate $CRON_HOURLY_DIR/ 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to move $OPENIDM_CONF_DIR/openidmLogRotate $CRON_HOURLY_DIR "
  
  addBCProviderToJavaSecurity
  
  logInfo "$CRON_SVC restart"
#  "$CRON_SVC" restart
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
# Function:    decryptPasswords                                                #
# Description: Updates various passwords like:                                 #
#               1) LDAP-admin user password                                    #
#               2) postgres admin user password                                #
#               3) openidm-admin user password                                 #
#               4) security-admin user password                                #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
decryptPasswords() {
  local opendjPasskey=/ericsson/tor/data/idenmgmt/opendj_passkey
  assertFileExists "${opendjPasskey}"
  local postgresPasskey=/ericsson/tor/data/idenmgmt/postgresql01_passkey
  assertFileExists "${postgresPasskey}"
  local openidmPasskey=/ericsson/tor/data/idenmgmt/openidm_passkey
  assertFileExists "${openidmPasskey}"
  local adminPasskey=/ericsson/tor/data/idenmgmt/secadmin_passkey
  assertFileExists "${adminPasskey}"
  local openidmPostgresEncryptedPwd=/ericsson/tmp/openidm/config/.openidm
  assertFileExists "${openidmPostgresEncryptedPwd}"

  logInfo "Updating passwords."

  logInfo "Decrypting Directory Manager password"
  assertPropertyExists $LDAP_ADMIN_PASSWORD
  decrypt $LDAP_ADMIN_PASSWORD $opendjPasskey DM_PWD
  assertDecrypted "$DM_PWD"

  logInfo "Decrypting Security Admin password"
  assertPropertyExists "$default_security_admin_password"
  decrypt $default_security_admin_password $adminPasskey SECURITY_ADMIN_PWD
  assertDecrypted "$SECURITY_ADMIN_PWD"

  logInfo "Decrypting Postgres Admin password"
  assertPropertyExists "$postgresql01_admin_password"
  decrypt $postgresql01_admin_password $postgresPasskey POSTGRES_OPENIDM_PWD
  assertDecrypted "$POSTGRES_OPENIDM_PWD"

  logInfo "Decrypting default OpenIDM Admin password"
  assertPropertyExists "$openidm_admin_password"
  decrypt $openidm_admin_password $openidmPasskey OPENIDM_PWD
  assertDecrypted "$OPENIDM_PWD"
  
  logInfo "Decrypting default openidm user password of openidm Postgres db"
  OPENIDM_PASSWD_ENC=$(cat $openidmPostgresEncryptedPwd) 
  decrypt $OPENIDM_PASSWD_ENC $postgresPasskey OPENIDM_REPO_USER_PWD
  assertDecrypted "$OPENIDM_REPO_USER_PWD"

  logInfo "Updating passwords finished successfully."
  logInfo "Brian is great decrypt pwds.... pwd: $POSTGRES_OPENIDM_PWD"
  return 0
}

#------------------------------------------------------------------------------#
# Function:    updatePasswordsInPostgres                                       #
# Description: Updates passwords in Postgres database:                         #
#              1) openidm-admin user password                                  #
#              2) openidm user password                                        #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
updatePasswordsInPostgres() {

   logInfo "Updating Postgres passwords"

   logInfo "Brian is great update t pwds top.... pwd: $POSTGRES_OPENIDM_PWD"

   assertPropertyExists "$POSTGRES_OPENIDM_PWD"
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
  local TMP_SQL_SCRIPT=$INST_TMP/localPassScr.pgsql
  local SQL_OUT=$INST_TMP/updatePasswd.out.$$

    cat << EOF > $TMP_SQL_SCRIPT
UPDATE openidm.internaluser SET pwd='$ENCRYPTED_PWD' \
WHERE objectid='$OPENIDM_USER';
EOF
  assertCommandExecuted "Failed to create temporary SQL script: $TMP_SQL_SCRIPT"

  logInfo "Updating $OPENIDM_USER encrypted password in Postgres"
  local passkey=/ericsson/tor/data/idenmgmt/postgresql01_passkey
  local PGSQL_ADMIN_PGPASSWORD=`echo $postgresql01_admin_password | $OPENSSL enc -a -d -aes-128-cbc -salt -kfile $passkey`
  PGPASSWORD=$PGSQL_ADMIN_PGPASSWORD $PSQL -U $POSTGRES_USER -h $POSTGRES_HOST -d $POSTGRES_DB_NAME -f $TMP_SQL_SCRIPT > $SQL_OUT 2>&1
  assertCommandExecuted "Failed to execute the temporary SQL script to update Postgres passwords. Refer to ${SQL_OUT} for more details."

 "$RM" -f $TMP_SQL_SCRIPT

  logInfo "Postgres passwords have been updated successfully into internaluser table"
  
  logInfo "Brian is great update t pwds bottom.... pwd: $POSTGRES_OPENIDM_PWD"
  return 0
}

#------------------------------------------------------------------------------#
# Function:    livesyncIssueCleanPostgresConfig                                #
# Description: In case of missing configurationni Postgres Livesync options    #
#              clean tables: configobjects, schedulerobjects and restart       #
# Parameters:  nothing                                                         #
# Exits:       0  success                                                      #
#              1  failure                                                      #
#------------------------------------------------------------------------------#
livesyncIssueCleanPostgresConfig() {

  logInfo "Brian is great livesyncCleanPos.... pwd: $POSTGRES_OPENIDM_PWD"
  logInfo "Cleaning Postgres config if <<trigger-activeSynchroniser_systemLdapAccount>> does not exist"

  assertPropertyExists "$POSTGRES_OPENIDM_PWD"

  logInfo "Checking if configuration contains <<trigger-activeSynchroniser_systemLdapAccount>>"
  local TMP_SCHEDULER_CHECK_OUT=$INST_TMP/checkConfig.out

  local passkey=/ericsson/tor/data/idenmgmt/postgresql01_passkey
  local PGSQL_ADMIN_PGPASSWORD=`echo $postgresql01_admin_password | $OPENSSL enc -a -d -aes-128-cbc -salt -kfile $passkey`
  PGPASSWORD=$PGSQL_ADMIN_PGPASSWORD $PSQL -U $POSTGRES_USER -h $POSTGRES_HOST -d $POSTGRES_DB_NAME \
         --quiet --command="SELECT count(*) FROM openidm.schedulerobjects WHERE objectid LIKE '%trigger-activeSynchroniser_systemLdapAccount%'" > $TMP_SCHEDULER_CHECK_OUT 2>&1
  assertCommandExecuted "Failed to execute SQL check script. Refer to ${TMP_SCHEDULER_CHECK_OUT} for more details."

  grep 0 $TMP_SCHEDULER_CHECK_OUT
  if [ $? == 0 ] ; then
    logInfo "Missing entries found - cleaning"
    local TMP_SQL_SCRIPT=$INST_TMP/cleanConfig.pgsql

    cat << EOF > $TMP_SQL_SCRIPT
DELETE FROM openidm.configobjects;
DELETE FROM openidm.schedulerobjects;
EOF
    assertCommandExecuted "Failed to create temporary SQL script: $TMP_SQL_SCRIPT"

    PGPASSWORD=$PGSQL_ADMIN_PGPASSWORD $PSQL -U $POSTGRES_USER -h $POSTGRES_HOST -d $POSTGRES_DB_NAME < $TMP_SQL_SCRIPT
    assertCommandExecuted "Failed to execute the temporary SQL script to clean configuration."

    "$RM" -f $TMP_SQL_SCRIPT
     logInfo "Postgres configuration cleaned"
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

  logInfo "Brian is great updateConfigFiles.... pwd: $POSTGRES_OPENIDM_PWD"
  POSTGRES_OPENIDM_PWD=$POSTGRES_OPENIDM_PWD
  export $POSTGRES_OPENIDM_PWD
  checkIfPropertiesExist
  logInfo "Brian is great updateConfigFiles.... pwd: $POSTGRES_OPENIDM_PWD"
  assertPropertyExists "$POSTGRES_OPENIDM_PWD"
  logInfo "Brian is great updateConfigFiles.... pwd: $POSTGRES_OPENIDM_PWD"

  AUTHENTICATION_JSON=${OPENIDM_CONF_DIR}/authentication.json
  logInfo "Updating: $AUTHENTICATION_JSON"
  "$SED" -e "s/UI_PRES_SERVER/$UI_PRES_SERVER/g" $AUTHENTICATION_JSON > $INST_TMP/authentication.json
  assertCommandExecuted "Failed to update: $AUTHENTICATION_JSON"
  "$CP" $INST_TMP/authentication.json $AUTHENTICATION_JSON 2>"$COMMAND_OUT_LOG"
  assertCommandExecuted "Failed to replace: $AUTHENTICATION_JSON"

  DATASOURCE_JDBC_DEFAULT_JSON=${OPENIDM_CONF_DIR}/datasource.jdbc-default.json
  logInfo "Updating: $DATASOURCE_JDBC_DEFAULT_JSON"
  "$SED" -e "s/POSTGRES_HOST/${POSTGRES_HOST}/g" -e "s/POSTGRES_OPENIDM_PASSWORD/${OPENIDM_REPO_USER_PWD}/g" $DATASOURCE_JDBC_DEFAULT_JSON > $INST_TMP/datasource.jdbc-default.json
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

  local obfKeystorePwd=`"$JAVA" -jar $OPENIDM_HOME/bundle/openidm-crypto-4.5.1.jar $OPENIDM_PWD 2>&1 | "$GREP" "OBF:"`
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
# Function:    createConfiguredFile                                            #
# Description: Create .openidm.configured file used for healthcheck            #
# Parameters:  nothing                                                         #
# Returns:     nothing                                                         #
#------------------------------------------------------------------------------#
createConfiguredFile() {
  "$TOUCH" "$OPENIDM_CONFIGURED_FILE"
}


# temporary until Mysql Server is not removed from Physical Environment;
# until LITP needs to access Mysql during upgrade  
#------------------------------------------------------------------------------#
# Function:    updatePasswordsInMySQL                                          #
# Description: update passwords for root / openidm users in mysql              #
# Parameters:  nothing                                                         #
# Returns:     0  success                                                      #
#------------------------------------------------------------------------------#
updatePasswordsInMySQL() {

  local mysqlPasskey=/ericsson/tor/data/idenmgmt/idmmysql_passkey
  eval MYSQL_OPENIDM_PWD="$("$ECHO" "$idm_mysql_admin_password" | "$OPENSSL" enc -a -d -aes-128-cbc -salt -kfile "$mysqlPasskey")"
  local TMP_SQL_SCRIPT=$INST_TMP/localPassScrMysql.sql
  local SQL_OUT=$INST_TMP/updatePasswdMysql.out.$$

    cat << EOF > $TMP_SQL_SCRIPT
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_OPENIDM_PWD') \
WHERE User='root';
UPDATE mysql.user SET Password=PASSWORD('$MYSQL_OPENIDM_PWD') \
WHERE User='openidm';
FLUSH PRIVILEGES;
quit
EOF
  
  $( /usr/bin/mysql --user=root --password=$MYSQL_OPENIDM_PWD \
            --host=idmdbhost < $TMP_SQL_SCRIPT > $SQL_OUT 2>&1 )
 
  if [ $? == 0 ]; then 
  	logInfo "Mysql passwords have been updated successfully into internaluser table"
  else
    logError "Mysql passwords have NOT been updated successfully into internaluser table"
  fi
  
  "$RM" -f $TMP_SQL_SCRIPT
  
  return 0
}
# end of Temporary

