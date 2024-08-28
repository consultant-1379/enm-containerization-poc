#!/bin/bash
##########################################################################
# COPYRIGHT Ericsson 2016
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
###########################################################################
#
# This script should be executed as a jboss post_start in SPS service group
#
################################################ 
#  Variables
################################################ 

# set default value before reading them from global.properties file

certificatesRevListDistributionPointServiceIpv4Enable=false
certificatesRevListDistributionPointServiceIpv6Enable=false
certificatesRevListDistributionPointServiceDnsEnable=false

publicKeyInfraRegAutorithyPublicServerName=notAssigned


#Read entries from global.properties
source /ericsson/tor/data/global.properties

PIB_CONFIG_COMMAND=/opt/ericsson/PlatformIntegrationBridge/etc/config.py


function configure_pki_cpds_values(){

# $1 host , $2 name $3 value

    host=$1
    config_param_name=$2
    config_param_value=$3

    logger -t CREDENTIAL_MGR_SPS -p user.notice "Running configure_pki_cpds_values on host $1 param $2 value $3"
    
    readValue=$($PIB_CONFIG_COMMAND read --app_server_address=$host --name=$config_param_name)
    returnValue=$?
    if [ "$returnValue" -ne 0 ] ; then
	logger -t CREDENTIAL_MGR_SPS -p user.err "Error during trying to read $config_param_name" 
	exit 1
    fi
    logger -t CREDENTIAL_MGR_SPS -p user.notice "readValue from PIB $config_param_name is $readValue" 

    echo $readValue | grep  $config_param_name > /dev/null 2>&1
    checkReadValue=$?

    # if we found on readValue value of variable it means it doesn't exist
    if [  "$checkReadValue" -eq  0   ] ; then 
	logger -t CREDENTIAL_MGR_SPS -p user.notice "element $config_param_name not found creating..." 
	$PIB_CONFIG_COMMAND create --app_server_address=$host --name=$config_param_name  --value=$config_param_value --scope=GLOBAL --type=String
	returnValue=$?
    fi

    if [[ ( "$readValue" == "[]" ) || ( -z "$readValue" ) ]] ; then
	logger -t CREDENTIAL_MGR_SPS -p user.err "element value $config_param_name empty try to update..." 
	$PIB_CONFIG_COMMAND update --app_server_address=$host --name=$config_param_name --value=$config_param_value --scope=GLOBAL --type=String
	returnValue=$?
	if [ "$returnValue" -ne 0 ] ; then
	    logger -t CREDENTIAL_MGR_SPS -p user.err "Error during trying to update $config_param_name" 
	fi
    fi

}

#main

logger -t CREDENTIAL_MGR_SPS -p user.notice "Running setCredCPDSValues script $(date  +'%d/%m/%Y %H:%M:%S:%3N')"

#hosts=("$sps1:8080" "$sps2:8080") 

# running only on our host name
hosts=$(hostname):8080

for host in "${hosts[@]}"
do

    logger -t CREDENTIAL_MGR_SPS -p user.notice "configuring cpds variables $host"

    configure_pki_cpds_values $host certificatesRevListDistributionPointServiceIpv4Enable $certificatesRevListDistributionPointServiceIpv4Enable 
    configure_pki_cpds_values $host certificatesRevListDistributionPointServiceIpv6Enable $certificatesRevListDistributionPointServiceIpv6Enable 
    configure_pki_cpds_values $host certificatesRevListDistributionPointServiceDnsEnable  $certificatesRevListDistributionPointServiceDnsEnable  
    # different name used within pib
    configure_pki_cpds_values $host publicKeyRegAutorithyPublicServerName                 $publicKeyInfraRegAutorithyPublicServerName        

done 

    logger -t CREDENTIAL_MGR_SPS -p user.notice "Running setCredCPDSValues script completed $(date  +'%d/%m/%Y %H:%M:%S:%3N')"

exit 0
