#!/bin/bash
cacert="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CYPHER_SHELL=/cypher-shell/cypher-shell
ADMIN_USER=neo4j
TIMEOUT=/usr/bin/timeout
NUMBER_OF_NEO4J_SERVERS=3

usage() { echo "Usage: $0 [-s <service1,service2,service3,....>] [-n <namespace>] [-c <number_of_neo_servers>]" 1>&2; exit 1; }

while getopts ":s:n:c:" arg; do
    case "${arg}" in
        s)
            services=${OPTARG}
            ;;
        n)
            NAMESPACE=${OPTARG}
            ;;
        c)
            NUMBER_OF_NEO4J_SERVERS=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${services}" ] || [ -z "${NAMESPACE}" ]; then
    usage
fi

check_readiness () {
service=$1
while true
do
  ${TIMEOUT} -s SIGUSR1 10s curl --silent --cacert $cacert --header "Authorization: Bearer $token"  https://kubernetes.default.svc/api/v1/namespaces/${NAMESPACE}/endpoints/${service} | grep -qw "addresses"
  if [ $? -eq 0 ] ;then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Service query ran successfully,  available : ${service}"
    break
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for service : ${service}"
    sleep 10
  fi
  done
}

check_neo4j () {
for ((instance=0;instance<${NUMBER_OF_NEO4J_SERVERS};instance++)); do
  while true ; do
    ADDRESS="graphdb-neo4j-${instance}.graphdb-neo4j.${NAMESPACE}.svc.cluster.local"
    check_cmd="${TIMEOUT} -s SIGUSR1 10s ${CYPHER_SHELL} -u ${ADMIN_USER} -p ${ADMIN_PASSWORD} --encryption=false -a ${ADDRESS} 'CALL ericsson.driver.ping(200);' 2>&1"
    check_cmd_log=$(echo ${check_cmd} | sed -e "s/${ADMIN_PASSWORD}/'******'/g")

    output=$(eval ${check_cmd})
    retcode=$?
    echo ${output} | grep TRUE > /dev/null 2>&1
    grep_true_retcode=$?
    if [ ${grep_true_retcode} -eq 0 ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Neo4j cypher query ping(200) ran successfully. Command: ${check_cmd_log}."
      break
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for Neo4j. Command: ${check_cmd_log}."
      sleep 30
    fi
  done
done

}

check_consul () {
while true ; do
  ADDRESS="consul.${NAMESPACE}.svc.cluster.local"
  check_cmd="${TIMEOUT} -s SIGUSR1 10s curl http://${ADDRESS}:8500/v1/status/leader 2>&1"
  output=$(eval ${check_cmd})
  retcode=$?
  echo ${output} | grep -E "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > /dev/null 2>&1
  grep_true_retcode=$?
  if [ ${grep_true_retcode} -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Consul leader query ran successfully. Command: ${check_cmd}."
    break
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for Consul"
    sleep 10
  fi
done

# Run neo4j password consul kv put
DPS_USER=$(curl http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/neo4j_dps_user_password?raw)
if [ -z ${DPS_USER} ] ; then
  curl -X PUT -d 'U2FsdGVkX1+J2hdySayWwRkWIlmCIaOmMb2nmcO41co=' http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/neo4j_dps_user_password
  if [ $? -ne 0 ] ; then
    echo "Failed to add DPS_USER consul kv"
    exit 1
  else
    echo "DPS_USER consul kv added successfully"
  fi
fi
ADMIN_USER=$(curl http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/neo4j_admin_user_password?raw)
if [ -z ${ADMIN_USER} ] ; then
  curl -X PUT -d 'U2FsdGVkX1/P9jBWu102gheAwRab6e3gevyXRPxPXCc=' http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/neo4j_admin_user_password
  if [ $? -ne 0 ] ; then
    echo "Failed to add ADMIN_USER consul kv"
    exit 1
  else
    echo "ADMIN_USER consul kv added successfully"
  fi
fi
READER_USER=$(curl http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/neo4j_reader_user_password?raw)
if [ -z ${READER_USER} ] ; then
  curl -X PUT -d 'U2FsdGVkX1+ybFosJuavTFVXWxbnrI5mrHiCJsH0s3s=' http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/neo4j_reader_user_password
  if [ $? -ne 0 ] ; then
    echo "Failed to add READER_USER consul kv"
    exit 1
  else
    echo "READER_USER consul kv added successfully"
  fi
fi

PASEO=$(curl http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/paseochair?raw)
if [ -z ${PASEO} ] ; then
  curl -X PUT -d 'LlD5I9YKSBwN1fFZvAX7Gg==' http://${ADDRESS}:8500/v1/kv/enm/deployment/databases/neo4j/paseochair
  if [ $? -ne 0 ] ; then
    echo "Failed to add PASEO consul kv"
    exit 1
  else
    echo "PASEO consul kv added successfully"
  fi
fi
}

IFS=","
for service in ${services}
do
case $service in
  neo4j)
         check_neo4j
         ;;
  consul)
         check_consul
         ;;
  *)
         check_readiness ${service}
esac
done
