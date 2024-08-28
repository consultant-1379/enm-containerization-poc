#!/bin/sh
#########################################
#
# Container Pre stop hook
# Run all pre stop scripts in $PRE_STOP
#
###########################################
#set -x  
source /ericsson/3pp/jboss/container-jms-jboss 

    info "Run container pre-stop scripts"
    __run_scripts_in_directory $PRE_STOP_DIR true

