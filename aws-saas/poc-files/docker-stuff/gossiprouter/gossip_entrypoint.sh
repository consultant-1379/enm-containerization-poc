#!/bin/bash

echo "starting service..." > /var/tmp/bg.txt
service rsyslog start

export CLASSPATH="/ericsson/3pp/jggossiprouters/lib_for_$GOSSIP_ROUTER_USAGE/*"
exec /usr/bin/java  -Dlog4j.configuration=file:/ericsson/3pp/jggossiprouters/lib_for_$GOSSIP_ROUTER_USAGE/log4j.properties -cp "$CLASSPATH" org.jgroups.stack.GossipRouter $@
