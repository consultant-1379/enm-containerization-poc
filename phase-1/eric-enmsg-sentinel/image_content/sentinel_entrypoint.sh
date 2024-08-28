#!/bin/bash

service rsyslog start
/etc/init.d/vmmonitord start

logger "Starting Sentinel Service.."
/opt/SentinelRMSSDK/bin/lserv
