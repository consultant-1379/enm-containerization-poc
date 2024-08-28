#!/bin/bash

# Set the envar to identify the server.
service rsyslog start


yum install -y ERICenmsggossiprouter_CXP9034239
logger "Starting gossiprouter for remoting"
service gossiprouter start
logger "Starting gossiprouter for caches" 
service gossiproutercaches start
logger "Gossip should be a'gossipin'.."
