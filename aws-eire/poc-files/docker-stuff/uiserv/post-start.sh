#!/bin/bash
#########################################
#
# Post start hook
# Check jboss is running and run post starts
#
###########################################

source /jboss-functions.sh

_post_start() {

  while true;
      do
  	__checkJBossServerRunning
  	if [ $? == 0 ]
  	   then
              info "Jboss server is running"
              break
  	fi
  done;
  
  __preDeploy
  
  if [ $? -ne 0 ]; 
     then
      $_RM -f $WAIT_FILE
       failure
      echo
      return 1
  fi
  
  find $JBOSS_HOME/standalone/tmp/deployments -type f -regex ".*[\.[erw]ar" -exec mv {} ${JBOSS_HOME}/standalone/deployments/ \;
  info "EAR/WAR/RAR available in deployments folder"
  _listDEs "$JBOSS_HOME/standalone/deployments"
  started=true

  count=0

  until [ $count -gt $STARTUP_WAIT ]
  do
    status 2> /dev/null
    if [ $? -eq 0 ] ; then
      launched=true
      break
    fi
    sleep 1
    let count=$count+1;
  done
  
  if [ "$launched" = "false" ] ; 
  then
      warn "$prog failed to startup in the time allotted"
      failure
      echo
      return 1
  fi
    
  monitor
    
  if [ $? -ne 0 ] ; 
    then
      error "$prog failed to start successfully."
      failure
      echo
      return 1
  fi
  
  
  # Only create lock file upon successfull start of JBoss
  $_CAT /dev/null > "$JBOSS_LOCKFILE"
  
  info "Run post-start scripts"
  __run_scripts_in_directory $POST_START_DIR true
  info "post-start scripts complete. JBOSS start complete."

}

_post_start
