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
timeout 2s $UTILITY_IF_FILE_EXISTS "$JMS_SERVER_RUNNING"
if [ $? -eq 0 ]
then
    /bin/rm -rf "$JMS_SERVER_RUNNING"
fi