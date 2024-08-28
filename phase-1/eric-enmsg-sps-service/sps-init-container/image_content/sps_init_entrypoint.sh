#!/bin/bash

bash /ericsson/3pp/jboss/entry_point.sh &

sleep 30

while true; do
   bash /var/tmp/spsCertificateCheck.sh
   if [ $? -eq 0 ]; then
       exit 0
   fi
   sleep 15
done