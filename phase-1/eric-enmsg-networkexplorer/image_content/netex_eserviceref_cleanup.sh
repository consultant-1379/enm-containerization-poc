#!/bin/sh
   
PG_PASSWORD="sfwk#db"
PGPASSWORD=$PG_PASSWORD /opt/rh/postgresql92/root/usr/bin/psql -Usfwk -d sfwkdb -h postgresql01 -c "Delete from eservice_info_data where eservice_id in (select id from eservice_info where id like '%netex#%' and service_application_package_name like 'cm-reader-ear%')" 1> /ericsson/3pp/jboss/standalone/log/netex_eserviceref_cleanup.log 2> /ericsson/3pp/jboss/standalone/log/netex_eserviceref_cleanup.log

PGPASSWORD=$PG_PASSWORD /opt/rh/postgresql92/root/usr/bin/psql -Usfwk -d sfwkdb -h postgresql01 -c "Delete from eservice_info where id like '%netex#%' and service_application_package_name like 'cm-reader-ear%'" 1>> /ericsson/3pp/jboss/standalone/log/netex_eserviceref_cleanup.log 2>> /ericsson/3pp/jboss/standalone/log/netex_eserviceref_cleanup.log
