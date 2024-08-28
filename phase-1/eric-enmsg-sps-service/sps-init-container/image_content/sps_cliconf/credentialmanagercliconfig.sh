#!/bin/bash

ERICCREDMANCLI_CONFIG_DIR="/etc/credm/conf.d"
ERICCREDMANCLI_CONFIGSOURCE_DIR="/ericsson/enm/sps_cliconf"
CLI_CONFFILE=credManagerCLI.conf

HOST_FOLDER=/ericsson/tor/data/credm/hosts
CONF_FOLDER=/ericsson/tor/data/credm/conf

#cp default conf files for credentialmanagercli


if [ ! -d $ERICCREDMANCLI_CONFIG_DIR ]; then
   echo   "local config source dir not present"
   mkdir -p $ERICCREDMANCLI_CONFIG_DIR
fi

cp $ERICCREDMANCLI_CONFIGSOURCE_DIR/$CLI_CONFFILE $ERICCREDMANCLI_CONFIG_DIR/$CLI_CONFFILE
echo  "copied cond file for credentialmanagercli.."

if [ ! -d $HOST_FOLDER ] ; then 
  mkdir -p  $HOST_FOLDER
fi
/bin/chown -R jboss_user:jboss  $HOST_FOLDER

if [ ! -d $CONF_FOLDER ] ; then 
  mkdir -p  $CONF_FOLDER
fi
/bin/chown -R jboss_user:jboss  $CONF_FOLDER

file=`hostname`
echo    "removing $HOST_FOLDER/$file if present"

/bin/rm -f $HOST_FOLDER/$file

echo  "end of  credentialmanagercliconfig.sh"
