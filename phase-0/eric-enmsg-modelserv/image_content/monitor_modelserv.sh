#!/bin/bash

# GLOBAL VARIABLES
ARG="monitor"

#///////////////////////////////////////////////
# Main Part of Script
#///////////////////////////////////////////////


initscript=/etc/init.d/modeldeployservice

bash $initscript $ARG > /dev/null 2>&1
ret=$?
if [[ "$ret" -eq 0 ]]; then
  exit 0
else
  exit 1
fi

