#!/bin/bash

#############################################################################################
#
#    PURPOSE: This script registers web contexts to mod cluster
#             By default web contexts are disabled.
#             This script is triggered by cron job- register_web_contexts which runs every minute
#
#
#############################################################################################
readonly ECHO="/bin/echo"
readonly TR="/usr/bin/tr"
readonly CURL="/usr/bin/curl"
readonly NC="/usr/bin/nc"
readonly GREP="/bin/grep"
readonly AWK="/bin/awk"
readonly SED="/bin/sed"
readonly GETENT="/usr/bin/getent"
readonly HOSTNAME='/bin/hostname'
readonly SERVICE="/sbin/service"
THIS_HOST=$($HOSTNAME)
MOD_CLUSTER_PORT="8666"

###########################################################################################
#  Check jboss status
###########################################################################################

check_jboss_state()
{
    $SERVICE jboss monitor
    return $?
}

###########################################################################################
#  Check if web contexts are already registered.
###########################################################################################

check_if_web_contexts_are_already_registered()
{
    $CURL -s -m 10 $instance:$MOD_CLUSTER_PORT/mod_cluster-manager | $SED -e 's/<br>\|<br\/>\|<h1>\|<h2>\|<h3>\|<pre>/\n/g' -e 's/<[^>]*>//g' | $GREP $THIS_HOST -A 8 | $GREP ENABLED

    response=$?
    logger "already registered response: " $response " instance: " $instance " host: " $THIS_HOST
    return $response
}

###########################################################################################
# Register web contexts.
###########################################################################################

register_web_context()
{
    logger "Registering jboss web contexts to $instance."
    MOD_CLUSTER_REGISTER_CONTEXTS_URL="http://$instance:$MOD_CLUSTER_PORT/mod_cluster-manager?Cmd=ENABLE-APP&Range=NODE&JVMRoute=$THIS_HOST"
    response=`$CURL -m 10 --write-out %"{http_code}" --connect-timeout 3 --silent --output /dev/null "$MOD_CLUSTER_REGISTER_CONTEXTS_URL"`
    check_if_web_contexts_are_already_registered
    registration_status=$?
    if [[ registration_status -eq 0  ]]
    then
      logger "Web contexts of $THIS_HOST host are registered successfully".
    else
      logger "Web contexts of $THIS_HOST host are not registered successfully. Response code $response is received for command $MOD_CLUSTER_REGISTER_CONTEXTS_URL"
    fi
}

#############################################################################################
#  Register web contexts in netex_instances to mod_cluster.
#############################################################################################

register_contexts_to_modcluster()
{
   #Setting jboss_status to 1 here, so that we don't have to run check_jboss_state for every httpd instance
   jboss_status=1
   for instance in $($GETENT hosts httpd-instance-1 | $AWK '{print $2}' | $AWK -F "." '{print $1}')
    do
       $NC -zvw 1 $instance $MOD_CLUSTER_PORT
       if [[ $? -eq 0 ]]
       then
         logger "$instance is up"
         check_if_web_contexts_are_already_registered
         rc=$?
         if [[ $rc -ne 0 ]]
         then
          logger "Web contexts are not registered yet. Status of web context registeration check is $rc"
          if [[ $jboss_status -eq 1 ]]
          then
            check_jboss_state
            jboss_status=$?
            if [[ $jboss_status -eq 0 ]]
            then
              #Register the contexts
              register_web_context
              registration_rest_reponse=$?
              #Check if contexts are registered
              check_if_web_contexts_are_already_registered
              registration_status=$?
              if [[ registration_status -eq 0  ]]
              then
                logger "Web contexts of $THIS_HOST host are registered successfully to $instance".
              else
                logger "Web contexts of $THIS_HOST host are not registered to $instance. Response of registration curl request is $registration_rest_reponse."
              fi
            else
               logger "Jboss service is not running on $THIS_HOST. Will not attempt to register Jboss web contexts on any httpd instance"
               exit 0
            fi
          fi
         fi
       else
         logger " $instance is not available. Will not attempt to register Jboss web contexts."
       fi
    done
}

#############################################################################################
#  Entry point of script
#############################################################################################
logger "${0} started."
register_contexts_to_modcluster
exit 0
