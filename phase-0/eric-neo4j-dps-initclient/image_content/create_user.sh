#!/bin/bash

neo4j_server_address=$1
username=$2
password=$3
role=$4
requirePasswordChange=$5

check_user_created_cypher () {
    cypher-shell/cypher-shell -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} --encryption=false -a bolt://${neo4j_server_address}:${NEO4J_BOLT_PORT}  \
    'CALL dbms.security.listUsers();' | grep $username
    retcode=$?
    if [ ${retcode} -eq 124 ]; then
        RETVAL=1
    elif [ ${retcode} -eq 0 ]; then
        RETVAL=${USER_ALREADY_CREATED_CODE}
    else
        RETVAL=0
    fi
    return $RETVAL
}

create_user () {
    cypher-shell/cypher-shell -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} --encryption=false -a bolt://${neo4j_server_address}:${NEO4J_BOLT_PORT}  \
    'CALL dbms.security.createUser('$username', '$password', '$requirePasswordChange');'
    retcode=$?
    if [ ${retcode} -eq 124 ]; then
        echo "Creating user " $username " timed out"
        RETVAL=1
    elif [ ${retcode} -eq 0 ]; then
        echo "User " $username " created successfully"
        RETVAL=0
    else
        echo "Creating user " $username " failed"
        RETVAL=1
    fi
#    return $RETVAL
}

assign_role () {
    cypher-shell/cypher-shell -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} --encryption=false -a bolt://${neo4j_server_address}:${NEO4J_BOLT_PORT}  \
    'CALL dbms.security.addRoleToUser('$role', '$username');'
    retcode=$?
    if [ ${retcode} -eq 124 ]; then
        echo "Assigning role '$role' to user '$username' timed out"
        RETVAL=1
    elif [ ${retcode} -eq 0 ]; then
        echo "Assigning role '$role' to user '$username' succeeded"
        RETVAL=0
    else
        echo "Assigning role '$role' to user '$username' failed"
        RETVAL=1
    fi
    return $RETVAL
}


create_user
assign_role
