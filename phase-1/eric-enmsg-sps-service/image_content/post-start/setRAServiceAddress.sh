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
# Pre-requisite : pki-manager-config-model configuration parameters and in SPS service group pki-manager related ears should be properly deployed.
################################################
#  Variables
################################################

#Read entries from global.properties
source /ericsson/tor/data/global.properties

PIB_CONFIG_COMMAND=/opt/ericsson/PlatformIntegrationBridge/etc/config.py

#Ports for different services like SCEP,CMP,CDPS,TDPS
scepport=8090
cmpport=8091
cdpsport=8092
tdpsport=8093

# running on SPS Host
spsHost=$(hostname):8080
echo "spsHost:" $spsHost

function configure_ra_service_addresses(){
   config_param_name=$1
   config_param_value=$2

   echo "Configuring the haproxysb ip address to "$config_param_name" configuration parameter"

   #Executing the PIB command from SPS SG's to set the haproxysb ip address to RA service configuration parameter
   $PIB_CONFIG_COMMAND update --app_server_address $spsHost --name=$config_param_name --value=$config_param_value
   
   if [ $? -ne 2 ]
   then
     raServiceAddressValue=`$PIB_CONFIG_COMMAND read --app_server_address $spsHost --name=$config_param_name`
   fi
   
   #Checking raServiceAddressValue
   if [ -z "$raServiceAddressValue" ]
   then
      echo "raServiceAddressValue of "$config_param_name "is not set from "$(hostname)
   else
      echo "raServiceAddressValue of "$config_param_name":"$raServiceAddressValue "from "$(hostname)
   fi
}

function configure_pki_ra_services(){
   #Configuration parameter values for different services like SCEP,CMP,CDPS,TDPS to set ipv4 address
   scepServiceAddress=$haproxysb:$scepport
   cmpServiceAddress=$haproxysb:$cmpport
   cdpsAddress=$haproxysb:$cdpsport
   tdpsAddress=$haproxysb:$tdpsport

   #Configuring ipv4 IP value to the different configuration parameters like scepServiceAddress,cmpServiceAddress,cdpsAddress,tdpsAddress
   configure_ra_service_addresses "scepServiceAddress" $scepServiceAddress
   configure_ra_service_addresses "cmpServiceAddress" $cmpServiceAddress
   configure_ra_service_addresses "cdpsAddress" $cdpsAddress
   configure_ra_service_addresses "tdpsAddress" $tdpsAddress
}

function configure_haproxysb_ipv4_address(){
   #Configuration parameter value for different services like SCEP,CMP,CDPS,TDPS to set ipv4 address
   sbLoadBalancerIPv4Address=`echo $haproxysb | awk -F"/" '{print $1}'`

   #Configuring ipv4 IP value to the sbLoadBalancerIPv4Address configuration parameter
   configure_ra_service_addresses "sbLoadBalancerIPv4Address" $sbLoadBalancerIPv4Address
}

function configure_haproxysb_ipv6_address(){
   #Since haproxysb IPv6 address is not present in the global.properties, so currently putting haproxysb IPv4 address to the sbLoadBalancerIPv6Address
   sbLoadBalancerIPv6Address=[`echo $haproxysb_ipv6 | awk -F"/" '{print $1}'`]

   #Configuring ipv6 IP value to the sbLoadBalancerIPv6Address configuration parameter
   configure_ra_service_addresses "sbLoadBalancerIPv6Address" $sbLoadBalancerIPv6Address
}

#main
echo "Running setRAServiceAddress script"

configure_pki_ra_services
configure_haproxysb_ipv4_address
configure_haproxysb_ipv6_address

echo "setRAServiceAddress script completed"

exit 0