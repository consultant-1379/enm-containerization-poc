#!/bin/bash

readonly CURL="/usr/bin/curl"
HTTP_PORT="8080"
_HOSTNAME='/bin/hostname'
THIS_HOST=$($_HOSTNAME)

JOIN_CLUSTER_URL="http://$THIS_HOST:$HTTP_PORT/mediationservice/res/cluster/join"

#MAIN
logger "Running curl command to join in mediationservice-router cluster"
response=$($CURL -m 10 --write-out %"{http_code}" --connect-timeout 3 --silent --output /dev/null "$JOIN_CLUSTER_URL")
logger "Response code $response is received for the command $JOIN_CLUSTER_URL"
exit 0
