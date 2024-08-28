#!/bin/bash
#########################################
#
# ADD USERS FROM CONFIGMAP
# THIS HAS TO BE DONE TO ALL NEO4J SERVERS
# N.B USERS ARE NOT REPLICATED BY NEO4J
#
##########################################

NEO4J_LEADER=''

INDEXES_FROM_FILE="/indexes/cm-indexes"
INDEXES_TO_DROP_FROM_FILE="/indexes/drop_user"
SERVERS=($(host "${NEO4J_BOLT_HOST}" | awk '/address/ {print $4}'))

_CYPHER_SHELL=cypher-shell/cypher-shell
MAX_ATTEMPTS=5
ERROR_RUNNING_CYPHER_QUERY_CODE=3

run_cypher_query() {

    if [ -z $2 ];then
        $_CYPHER_SHELL -u  $ADMIN_USER -p $ADMIN_PASSWORD -a bolt://"${NEO4J_LEADER}:${NEO4J_BOLT_PORT}" "$1"
    else
        $_CYPHER_SHELL -u  $ADMIN_USER -p $ADMIN_PASSWORD -a bolt://"$1:${NEO4J_BOLT_PORT}" "$2"
    fi
}

run_cypher_query_with_retry(){
   attempt="1"
   while [ $attempt -le $MAX_ATTEMPTS ]
   do
     run_cypher_query "$1"
     ret_code=$?
     if [ $ret_code -eq 0 ]; then
        exit_code=0
        break
     fi
     echo "Failed to run cypher query retry $attempt of $MAX_ATTEMPTS. return code: ${ret_code}"
     attempt=$[$attempt+1]
     exit_code=${ERROR_RUNNING_CYPHER_QUERY_CODE}
   done
   return $exit_code
}

create_users() {
    for f in /config/*; do
        USERS=$(cat $f | jq '.[]')
        echo $USERS | jq -rc '.' | while IFS='' read user ;do
            username=$(echo "$user" | jq .username)
            password=$(echo "$user" | jq .password)
            role=$(echo "$user" | jq .role)
            requirePasswordChange=$(echo "$user" | jq .requirePasswordChange)

            for server in "${SERVERS[@]}";do
              bash create_user.sh  $server $username $password $role $requirePasswordChange
            done

        done
   done
}

find_leader() {
        for server in "${SERVERS[@]}";do
                ROLE=$(run_cypher_query $server "CALL dbms.cluster.role()"|grep LEADER)
                if [ $? -eq "0" ]; then
                        NEO4J_LEADER=$server
                        break
                fi
        done
}

add_node_model() {
    run_cypher_query "MATCH (n:NodeModel) RETURN n" | grep NodeModel
    result=$?
    if [ "$result" -eq "0" ]; then
        echo "NodeModel already present, not creating."
    else
        echo "NodeModel not present, creating."
        run_cypher_query  "CREATE (n:NodeModel {label: 'PersistenceObject', \` _internalId\`: 'long', \` _createdTime\`: 'Date', \` _lastUpdatedTime\`: 'Date', \` _level\`: 'short'})"
        echo "Creating NodeModel constraints."
        run_cypher_query "CREATE CONSTRAINT ON ( nodemodel:NodeModel ) ASSERT nodemodel.label IS UNIQUE"
        run_cypher_query "CREATE CONSTRAINT ON ( relationshipmodel:RelationshipModel ) ASSERT relationshipmodel.type IS UNIQUE"
    fi
}

manage_user_defined_indexes() {
    INDEXES_FROM_SERVER=`run_cypher_query "CALL db.indexes() YIELD description"`
    log_existing_indexes "$INDEXES_FROM_SERVER"
    delete_user_defined_indexes "$INDEXES_FROM_SERVER"
    exit_code=$?
    create_user_defined_indexes "$INDEXES_FROM_SERVER"
    ret_code=$?
    if [ $exit_code -ne 0 ]; then
       exit $exit_code
    fi
    if [ $ret_code -ne 0 ]; then
       exit $ret_code
    fi
}
create_user_defined_indexes() {
    exit_code=0
    INDEXES_FROM_SERVER="$1"
    while IFS=\| read -r INDEX_NAME INDEX_QUERY || [[ -n "$INDEX_QUERY" ]]; do
        if grep -q "$INDEX_NAME" <<< $INDEXES_FROM_SERVER; then
            echo "User defined index already exists: $INDEX_NAME"
        else
            echo "Creating new user defined index: $INDEX_NAME"
            run_cypher_query_with_retry "CREATE $INDEX_QUERY"
            ret_code=$?
            if [[ "${ret_code}" -eq "${ERROR_RUNNING_CYPHER_QUERY_CODE}" ]]; then
              echo "Failed to create new user defined index: $INDEX_NAME"
              exit_code=3
            fi
           echo "Created new user defined index: $INDEX_NAME"
        fi
    done < <(tail -n +5 $INDEXES_FROM_FILE)
    return $exit_code
}


delete_user_defined_indexes() {
    exit_code=0
    INDEXES_FROM_SERVER="$1"
    while IFS=\| read -r INDEX_NAME INDEX_QUERY || [[ -n "$INDEX_QUERY" ]]; do
        if grep -q "$INDEX_NAME" <<< $INDEXES_FROM_SERVER; then
            echo "Deleting user defined index: $INDEX_NAME"
            run_cypher_query_with_retry "DROP $INDEX_QUERY"
            ret_code=$?
            if [[ "${ret_code}" -eq "$ERROR_RUNNING_CYPHER_QUERY_CODE" ]]; then
              echo "Failed to delete user defined index: $INDEX_NAME"
              exit_code=3
            fi
            echo "Deleted user defined index: $INDEX_NAME"
        fi
    done < <(tail -n +5 $INDEXES_TO_DROP_FROM_FILE)
    return $exit_code
}


log_existing_indexes() {
    INDEXES_FROM_SERVER="$1"
    echo "#######################################################"
    echo "Following Indexes exist on server:"
    IFS_BAK=$IFS
    IFS=$'\n'
    for index in $INDEXES_FROM_SERVER; do
        echo "$index"
    done
    IFS=$IFS_BAK
    IFS_BAK=
    echo "#######################################################"
}

############################################################################
#
# HOOK FOR  POST CONFIG CUSTOM SCRIPTS
# PATH /post-config-scripts/
#
############################################################################
execute_post_config_custom_scripts() {
    for f in /post-config-custom-scripts/*; do
       echo "executing script $f"
       bash $f
    done 
}

############################################################################
#
# HOOK FOR  PRE CONFIG CUSTOM SCRIPTS
# PATH /pre-config-scripts/
#
############################################################################
execute_pre_config_custom_scripts() {
    for f in /pre-config-custom-scripts/*; do
       echo "executing script $f"
       bash $f
    done 
}

execute_pre_config_custom_scripts
create_users
find_leader
add_node_model
manage_user_defined_indexes
execute_post_config_custom_scripts
