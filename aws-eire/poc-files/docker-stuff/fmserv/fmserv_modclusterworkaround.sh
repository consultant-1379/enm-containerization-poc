#!/bin/bash

#############################################################################################
#
#    PURPOSE: This script registers any mod_cluster contexts for the calling service on httpd
#    This script is called as part of the health check scripts.
#
#
#############################################################################################
readonly ECHO="/bin/echo"
readonly TR="/usr/bin/tr"
readonly CURL="/usr/bin/curl"
readonly NC="/usr/bin/nc"
readonly GREP="/bin/grep"
readonly SED="/bin/sed"
readonly GETENT="/usr/bin/getent"
SCRIPT_NAME="${0}"
readonly HOSTNAME='/bin/hostname'
readonly SERVICE="/sbin/service"
THIS_HOST=$($HOSTNAME)

#############################################################################################
#
#  Check Jboss State and Register web contexts in fmserv_instances to mod_cluster.
#  Returns: nothing
#  Arguments: nothing
#
#############################################################################################

checkJbossStateAndRegisterContext()
{
   $SERVICE jboss monitor
   rc=$?
   if [ $rc -eq 0 ] ; then
     #check and register webcontext
     register_contexts_to_modcluster
   fi

}

#############################################################################################
#
#  Register web contexts in fmserv_instances to mod_cluster.
#  Returns: nothing
#  Arguments: nothing
#
#############################################################################################

register_contexts_to_modcluster()
{
    for instance in $($GETENT hosts httpd-instance-1 | awk '{print $2}' | awk -F "." '{print $1}')
    do
       #Check if httpd instances are up
       $NC -zvw 1 $instance $MOD_CLUSTER_PORT
       if [[ $? -eq 0 ]]
       then
         #Check if contexts of this host are already registered in modcluster or not.
         CONTEXT_RESPONSE=$($CURL -s -m 10 $instance:$MOD_CLUSTER_PORT/mod_cluster-manager | $SED -e 's/<br>\|<br\/>\|<h1>\|<h2>\|<h3>\|<pre>/\n/g' -e 's/<[^>]*>//g' | $GREP $THIS_HOST -A 8 | $GREP ENABLED)
         rc=$?
         if [[ $rc -ne 0 ]]
         then
           #Register all contexts of this node to modcluster.
           MOD_CLUSTER_REGISTER_CONTEXTS_URL="http://$instance:$MOD_CLUSTER_PORT/mod_cluster-manager?Cmd=ENABLE-APP&Range=NODE&JVMRoute=$JVM_ROUTE_VALUE"
           response=$($CURL -m 10 --write-out %"{http_code}" --connect-timeout 3 --silent --output /dev/null "$MOD_CLUSTER_REGISTER_CONTEXTS_URL")
           logger "Response code $response is received for the command $MOD_CLUSTER_REGISTER_CONTEXTS_URL"
         fi
       else
         logger "$instance is not up.So Context will not be registered in this cycle."
       fi
    done

}

#############################################################################################
#
#  Main part of the program
#
#############################################################################################

JVM_ROUTE_VALUE="$THIS_HOST"
MOD_CLUSTER_PORT="8666"
checkJbossStateAndRegisterContext

exit 0
