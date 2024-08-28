#!/bin/bash
##########################################################################
# COPYRIGHT Ericsson 2018
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################
#
# This script should be executed as a jboss pre_stop in SPS service group
#
################################################
#  Variables
################################################
readonly DDC_DATA_PATH="/var/ericsson/ddc_data/$(hostname)_TOR/config"

logger -t SPS_CACHE "verifying the stateTransferInProgress value for SPS caches"

rep_state=`/opt/ericsson/ERICddc/util/bin/instr -defaultPollInterval 1 -maxtime 3 -metrics '$(DDC_DATA_PATH)'/SupportedAlgorithmsCacheConfig.xml | awk '/cache-SupportedAlgorithmsCache-state/ && /true|false/{ print $4 }'`
logger -t SPS_SUPPORTED_ALGORITHM_CACHE "stateTransferInProgress is $rep_state"

while [ -n "$rep_state" ] && $rep_state
do
        rep_state=`/opt/ericsson/ERICddc/util/bin/instr -defaultPollInterval 1 -maxtime 3 -metrics '$(DDC_DATA_PATH)'/SupportedAlgorithmsCacheConfig.xml | awk '/cache-SupportedAlgorithmsCache-state/ && /true|false/{ print $4 }'`
        logger -t SPS_SUPPORTED_ALGORITHM_CACHE "stateTransferInProgress is again $rep_state"
done

logger -t SPS_SUPPORTED_ALGORITHM_CACHE "stateTransferInProgress before exit $rep_state"

rep_state=`/opt/ericsson/ERICddc/util/bin/instr -defaultPollInterval 1 -maxtime 3 -metrics '$(DDC_DATA_PATH)'/PkiWebCliExportCacheConfig.xml | awk '/cache-PkiWebCliExportCache-state/ && /true|false/{ print $4 }'`
logger -t SPS_PKI_WEB_CLI_CACHE "stateTransferInProgress is $rep_state"

while [ -n "$rep_state" ] && $rep_state
do
        rep_state=`/opt/ericsson/ERICddc/util/bin/instr -defaultPollInterval 1 -maxtime 3 -metrics '$(DDC_DATA_PATH)'/PkiWebCliExportCacheConfig.xml | awk '/cache-PkiWebCliExportCache-state/ && /true|false/{ print $4 }'`
        logger -t SPS_PKI_WEB_CLI_CACHE "stateTransferInProgress is again $rep_state"
done

logger -t SPS_PKI_WEB_CLI_CACHE "stateTransferInProgress before exit $rep_state"

exit