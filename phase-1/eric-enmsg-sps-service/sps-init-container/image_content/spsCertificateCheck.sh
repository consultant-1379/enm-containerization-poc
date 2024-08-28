#!/bin/bash

LOCK_JBOSS_RESTART="/ericsson/credm/service/removetojbossrestart.lock"

if [[ ! -e  $LOCK_JBOSS_RESTART ]] ; then
  logger -t CREDENTIAL_MGR_SERVICE  -p user.notice "Invoking JBOSS restart to reload credentials"
  exit 0
fi

exit 1
