#!/bin/bash

# Init script to install & configure uiserv SG container

service rsyslog start

yum install -y ERICenmsguiservice_CXP9031574

logger "bugs for check service availabilityi workaround"
/bin/cp -f /var/tmp/check_service_availability.sh /ericsson/3pp/jboss/bin/

/bin/cp -f /var/tmp/rename_currentxml.sh /ericsson/3pp/jboss/bin/post-start/

logger "starting service"
/etc/init.d/vmmonitord start
/etc/init.d/jboss start

