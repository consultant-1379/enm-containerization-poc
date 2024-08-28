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
if ! [[ -f "$JMS_SERVER_RUNNING" ]]; then
  /bin/touch "$JMS_SERVER_RUNNING"
fi

