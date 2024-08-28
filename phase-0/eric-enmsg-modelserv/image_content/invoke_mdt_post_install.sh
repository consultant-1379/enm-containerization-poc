#!/bin/bash
######################################################################################
# This script will invoke the second run of MDT after successful install.
######################################################################################

# GLOBAL VARIABLES
_CONSUL="http://consul:8500/v1/kv"

DEPLOYMENT_STATUS="enm/applications/lifecycle_management/services/vnflcm/enm-deploymentworkflows/status/models"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Updating consul kv key to invoke modelsserv watcher"

curl -X PUT -d 'complete' ${_CONSUL}/${DEPLOYMENT_STATUS}
if [ $? -eq 0 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Consul key ${DEPLOYMENT_STATUS} set to complete"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to set consul key ${DEPLOYMENT_STATUS}"
  exit 1
fi
# allow consul trigger watch
sleep 120
while true; do
  KEY_VALUE=$(curl $_CONSUL/${DEPLOYMENT_STATUS}?raw)
  if [[ "$KEY_VALUE" == *"MDT_success"* ]];then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Post install deploy complete - value : ${KEY_VALUE}"
    exit 0
  elif [[ "$KEY_VALUE" == *"MDT_fail"* ]];then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Post Install MDT failed - value : ${KEY_VALUE}"
    exit 1
  elif [[ "$KEY_VALUE" == *"complete"* ]];then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Nothing to do - value : ${KEY_VALUE}"
    exit 0
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting on post model deploy to complete - value set to : ${KEY_VALUE}"
    sleep 10
  fi
done