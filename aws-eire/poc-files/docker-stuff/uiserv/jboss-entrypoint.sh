#!/bin/sh

bash /var/tmp/uiserv_config_entrypoint.sh

source /jboss-functions.sh 

bash /post-start.sh &

_start
