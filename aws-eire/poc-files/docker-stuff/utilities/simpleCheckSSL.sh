#!/bin/bash

grep "#SSLHonorCipherOrder o" /etc/httpd/conf/httpd.conf > /dev/null

if [ $? -eq 0 ]
then 
 echo "SSL appears to be off"
else
 echo "SSL appears to be on"
fi

