#!/bin/sh
#########################################
#
# Post start hook
# Check jboss is running and run post starts
#
###########################################
#set -x  
source /ericsson/3pp/jboss/container-jms-jboss 
 
_post_start() {
 
  while true;
      do
        status
        if [ $? == 0 ]
           then
              info "Jboss server is running"
              break
        elif [ $? -eq 4 ]; then
             __process_hornetq_journals
        fi 
        sleep 10
  done;
 

  info "Run post-start scripts"
  __run_scripts_in_directory $POST_START_DIR true  
  /etc/init.d/vmmonitord start
  
}
 
_post_start
