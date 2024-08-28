#!/bin/bash -x
#######################################################################################
#
# THIS SCRIPT IS TECHNICAL DEBT TO ALLOW CONSISTENT DEPLOYMNET OF ENM IN CLOUD POC/TRIAL
# A MORE SUSTAINABLE SOLUTION IS REQUIRED LONG TERM
########################################################################################
SCRIPT_NAME=$(basename ${0})
LOG_TAG="POSTGRES-$(hostname -s)"
PSQL=/opt/rh/postgresql92/root/usr/bin/psql
_GREP=/bin/grep
CHECK_THRESHOLD="select * from configuration_parameter where id = 'GLOBAL___databaseSpaceCriticalThreshold';"
#######################################################################
#
# critical threshold value set to 1000 Megabytes
#
# Arguments: None
# Returns: 0
#
########################################################################
insert_critical_threshold()
{
  echo "starting critical threshold update"
  su - postgres -c "psql -d sfwkdb -c 'insert into configuration_parameter (id,description,last_modification_time,name,namespace,property_scope,status,type_as_string,single_value) values ('\'GLOBAL___databaseSpaceCriticalThreshold\'','\'The_amount_of_free_space_in_megabytes_which_must_be_available_in_the_database_to_support_write_operations\'',1474364749643,'\'databaseSpaceCriticalThreshold\'','\'global\'','\'GLOBAL\'','\'MODIFIED\'','\'java.lang.Integer\'',1000);'"
}

CHECK_THRESHOLD_COMMAND=$($PSQL -h postgresql01 -U postgres -d sfwkdb -c "$CHECK_THRESHOLD" -o /tmp/check_threshold)
VALUE=$($_GREP GLOBAL___databaseSpaceCriticalThreshold -c /tmp/check_threshold)

if [ $VALUE -eq 0 ]
then
  insert_critical_threshold
  echo "Critical Threshold value inserted"
fi
