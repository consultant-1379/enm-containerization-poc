#!/bin/bash

service rsyslog start

logger "modifying permission and users..."
useradd -u 501 -g 205 enmadm 
groupmod -g 206 jboss
groupadd enm -g 205
#usermod -g 205 enmadm

#usermod -g 205 enmadm
#groupdel enm
groupmod -n enm jboss
groupadd jboss -g 206
groupmems -g jboss -a jboss_user
groupmems -g jboss -a enmadm
groupmems -g enm -a jboss_user
groupmems -g enm -a enmadm
chgrp enm /home
chgrp enm /ericsson
chmod 775 /home
chmod 775 /ericsson

