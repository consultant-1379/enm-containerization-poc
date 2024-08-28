#!/bin/bash

service rsyslog start


SCRIPT_NAME=$(basename ${0})
LOG_TAG="NEO4J-$(hostname -s)"

# add user and group
/usr/sbin/groupadd neo4j
retcode=$?
if [[ $retcode -ne 9 && $retcode -ne 0 ]]; then
    error "Failed to add group neo4j. return code: $retcode."
    exit 1
fi
/usr/sbin/useradd -g neo4j neo4j
retcode=$?
if [[ $retcode -ne 9 && $retcode -ne 0 ]]; then
    error "Failed to add user neo4j. return code: $retcode."
    exit 1
fi

echo $(hostname -s) | tr '[:upper:]' '[:lower:]' | (sed -i.bak 's/%%_VM_NAME_%%/'$(xargs)'/g' /etc/consul.d/agent/config.json)
echo $(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1) | (sed -i.bak 's/%%_ETH0_%%/'$(xargs)'/g' /etc/consul.d/agent/config.json)

/usr/bin/consul agent --config-dir=/etc/consul.d/agent &

IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
# install Neo4j Service Group RPM
/usr/bin/yum install -y ERICenmsgneo4j_CXP9034341


# Setup Neo4j
/opt/ericsson/com.ericsson.oss.servicegroupcontainers.neo4j/dbscripts/setup_and_start_neo4j.sh \
  --service-instance-name=$(hostname) \
  --admin-password=Neo4jadmin123 \
  --dps-user-password=Neo4juser123 \
  --reader-user-password=Neo4juser123 \
  --service-name=neo4j \
  --internal-ip=$IP_ADDRESS \
  --internal-ip-list=$IP_ADDRESS
