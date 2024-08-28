#!/bin/bash
service vmmonitord start
yum install -y httpd
echo hello > /var/www/html/index.html
service httpd start
mkdir -p /usr/lib/ocf/resource.d/
while true
do
  sleep 10
done
