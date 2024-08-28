#!/bin/bash

service rsyslog start

yum install ERICenmsentinellicensemanager_CXP9033766.x86_64 -y

logger "Simulating Sentinel SG RPM post install"
  
sed -i 's/\/opt\/SentinelRMSSDK\/licenses\/lservrc/\/ericsson\/sentinel_lic\/lservrc/g' /etc/sysconfig/sentinel
touch /ericsson/sentinel_lic/lservrc

logger "not adding kv key for backup"
logger "Starting Sentinel License service..."
service sentinel start
