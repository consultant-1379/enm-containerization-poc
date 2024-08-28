#!/bin/bash
source /ericsson/tor/data/global.properties
HAPROXY_POD_IP=$(dig +short haproxy-0.haproxy.default.svc.cluster.local)
HAPOXY_HOST_IP=$(getent hosts sso.${UI_PRES_SERVER} | awk '{print $1}')

if [[ ${HAPROXY_POD_IP} != ${HAPOXY_HOST_IP} ]]
then
  logger -t "HAPROXY_IP_CHECK" "Restarting httpd-enm service"
  cp -f /etc/hosts /tmp/hosts
  sed -i.bak "/${UI_PRES_SERVER}/d" /tmp/hosts
  echo -e "${HAPROXY_POD_IP} sso.${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /tmp/hosts
  #echo -e "${HAPROXY_POD_IP} ${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /tmp/hosts
  cp -f /tmp/hosts /etc/hosts
  /etc/init.d/httpd-enm stop
  /etc/init.d/httpd-enm start
fi
