#!/bin/bash

service rsyslog start
service sshd start

SCRIPT_NAME=$(basename ${0})
LOG_TAG="POSTGRES-$(hostname -s)"

GREP=/bin/grep
sed -i "s/$(hostname)/$(hostname) postgresql01/g" /etc/hosts

yum install -y postgresql92-postgresql-contrib-9.2.7-1.1.el6.x86_64
yum install -y ERICenmsgpostgres_CXP9033553
yum install -y ERICddc_CXP9030294

#run postinstall again
/var/tmp/postinstall

# Modify the postgres user to be in the correct group
usermod -a -G enm postgres
# Set the timezone for postgres
export PGTZ=`cat /etc/sysconfig/clock | grep ZONE | awk -F'=' '{print $2}' | sed 's/"//g'`;
export PGTZ_SED=$(echo ${PGTZ} | sed 's/\//\\\//g')
sed -i "s/^timezone = .*/timezone = '${PGTZ_SED}'/g" /tmp/postgresql.conf

# Allow remote access
echo "host    all             all             0.0.0.0/0            trust" >> /tmp/pg_hba.conf

# database space crtitical threshold update
echo "./var/tmp/update_critical_size_threshold.sh" >> /etc/rc.local
#bash /etc/rc.local

