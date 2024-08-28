CONSUL="http://10.10.0.157:8500/v1/kv"
VALUE=(python -c 'import sys, json; print json.load(sys.stdin)[0]["Value"]')
FOLDER_CREDENTIALS="$JBOSS_HOME/standalone/data/dps/credentials"
CONSUL_KV="enm/deployment/databases/neo4j/neo4j_dps_user_password"
CONSUL_KV_PASS_KEY="enm/deployment/databases/neo4j/paseochair"
NEO4J_PROPERTIES="neo4j.properties"
GLOBAL_PROPERTIES_FILE="/ericsson/tor/data/global.properties"
PASSKEY_FILE="/ericsson/tor/data/idenmgmt/neo4j_passkey"
DPS_PASSWORD_KEY_PREFIX="neo4j_dps_user_password="
OPENSSL_CMD="/usr/bin/openssl"
GREP_CMD="/bin/grep"
#***********************************************************#
# info ()                                                   #
# Prints out $msg to the default log file                   #
# Parameter: $msg the msg to print out                      #
# Returns: 0 on success, $E_LOGGING                         #
#-----------------------------------------------------------#
function info() {
    local MSG=${@}
    logger -s -t SETUP_DPS_NEO4J_RESOURCE_ADAPTER -p user.notice "INFO $MSG"
    return 0
}
#***********************************************************#
# error ()                                                  #
# Prints out $msg to the default log file                   #
# Parameter: $msg the msg to print out                      #
# Returns: 0 on success, $E_LOGGING                         #
#-----------------------------------------------------------#
function error() {
    local MSG=${@}
    logger -s -t SETUP_DPS_NEO4J_RESOURCE_ADAPTER -p user.err "ERROR $MSG"
    return 0
}
function configure_neo4j_credentials() {
    $($GREP_CMD -i "DDC_ON_CLOUD=TRUE" $GLOBAL_PROPERTIES_FILE > /dev/null)
    retcode=$?
    if [ $retcode -eq 0 ]; then
       configure_cloud_neo4j_credentials
    else
       configure_physical_neo4j_credentials
    fi
}
function configure_cloud_neo4j_credentials() {
    info "Configuring neo4j credentials on cloud."
    #CREDENTIAL=$($CONSUL kv get $CONSUL_KV)
    CREDENTIAL=$(curl $CONSUL/$CONSUL_KV | "${VALUE[@]}" | base64 --decode )
    retcode=$?
    if [ $retcode -ne 0 ]; then
        error "Failed to get the neo4j dps user password from KV store. return code: ${retcode}. Output: $CREDENTIAL"
        return $retcode
    fi
    #PASS_KEY=$($CONSUL kv get -stale $CONSUL_KV_PASS_KEY)
    PASS_KEY=$(curl $CONSUL/$CONSUL_KV_PASS_KEY | "${VALUE[@]}" | base64 --decode )
    ret_code=$?
    if [ $ret_code -ne 0 ]; then
        log_error "Failed to get neo4j pass_key from KV store. return code: ${ret_code}."
        return 1
    fi
    PASSWORD=$(echo "$CREDENTIAL" | ${OPENSSL_CMD} enc -aes-128-cbc -d -a -k ${PASS_KEY})
    retcode=$?
