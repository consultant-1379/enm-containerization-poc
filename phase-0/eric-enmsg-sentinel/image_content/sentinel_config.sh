#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
service rsyslog start

yum install -y ERICenmsgsentinel_CXP9034391

logger "Simulating Sentinel SG RPM post install"

sed -i 's/\/opt\/SentinelRMSSDK\/licenses\/lservrc/\/ericsson\/sentinel_lic\/lservrc/g' /etc/sysconfig/sentinel
touch /ericsson/sentinel_lic/lservrc

logger "not adding kv key for backup"
logger "Starting Sentinel License service..."
/etc/init.d/vmmonitord start
service sentinel start

