#!/bin/bash

echo "$(date +'%b %d %T') INFO post install, running MSCM update_ulimit_openfiles"

ENM_LIMIT_FILE99="/etc/security/limits.d/99-enmlimits.conf"

if [[ -f $ENM_LIMIT_FILE99 && -w $ENM_LIMIT_FILE99 ]]; then
    /usr/bin/perl -pi -e    's/jboss_user.*nofile.*/jboss_user          -    nofile     15240/g' $ENM_LIMIT_FILE99
    echo "$(date +'%b %d %T') INFO post install, MSCM update_ulimit_openfiles completed"
else
    echo "$(date +'%b %d %T') ERROR post install, MSCM update_ulimit_openfiles failed, $ENM_LIMIT_FILE99 does not exist or not writeable."
fi
