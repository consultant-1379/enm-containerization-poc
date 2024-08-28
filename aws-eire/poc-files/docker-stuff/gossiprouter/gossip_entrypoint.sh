#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi

service rsyslog start
/etc/init.d/vmmonitord start

export CLASSPATH="/ericsson/3pp/jggossiprouters/lib_for_$GOSSIP_ROUTER_USAGE/*"
exec java  -Dlog4j.configuration=file:/ericsson/3pp/jggossiprouters/lib_for_$GOSSIP_ROUTER_USAGE/log4j.properties -cp "$CLASSPATH" org.jgroups.stack.GossipRouter $@
