#!/bin/bash

# Set the envar to identify the server.
service rsyslog start


yum install -y ERICenmsgsso_CXP9031582.noarch

# increase timeout for jboss
IP_ADDRESS=$(ip addr show eth0 | grep -w inet | awk '{print $2}' | cut -d / -f 1)
sed -i "s/127.0.0.1/${IP_ADDRESS}/g" /ericsson/3pp/jboss/bin/standalone.conf
sed -i "s/JB_MANAGEMENT=/JB_MANAGEMENT=127.0.0.1/g" /ericsson/3pp/jboss/bin/standalone.conf

echo -e "\nSTARTUP_WAIT=21600" >> /ericsson/3pp/jboss/jboss-as.conf

logger "cluster ID possible BUG workaround"
sed -i "s/\$(NF-1)/\$1/g" /ericsson/3pp/jboss/bin/configure_production_env.sh

sed -i "s/MAX_REPEAT_WAIT_SECOND_SSO = 2880/MAX_REPEAT_WAIT_SECOND_SSO = 20/"g /opt/ericsson/sso/bin/python/sso_const.py
