#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2015
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
# This script requires bash 4 or above
# $Date: 2015-03-31$
# $Author: Fei$
###########################################################################
if [ ! -d "$JBOSS_MESSAGING_DATA_DIRECTORY" ]; then
  /bin/mkdir -p "$JBOSS_MESSAGING_DATA_DIRECTORY"
fi
USER_NAME=$(/bin/ls -ld $JBOSS_MESSAGING_DATA_DIRECTORY | awk '{print $3}')
if [ "$USER_NAME" != jboss_user ]; then
  /bin/chown -R jboss_user:jboss "$JBOSS_MESSAGING_DATA_DIRECTORY"
fi

if [[ -e "$JMS_SERVER_RUNNING" ]]; then
  /bin/rm -rf "$JMS_SERVER_RUNNING"
fi
