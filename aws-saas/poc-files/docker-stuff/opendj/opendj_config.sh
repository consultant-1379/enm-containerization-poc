#!/bin/bash

service rsyslog start

#SCRIPT_NAME=$(basename ${0})
#LOG_TAG="OPENDJ-$(hostname -s)"
##ENM_UTILS=/opt/ericsson/enm-configuration/etc/enm_utils.lib
##OPENDJ_VARIABLES=/opt/ericsson/com.ericsson.oss.security/idenmgmt/opendj/variables
#
##This needs to change
# sed -i "s/ldap-local/ldap-local $(hostname)/g" /etc/hosts
#
## Set the envar to identify the server.
# echo -e "\nexport SERVICE_INSTANCE_NAME= $(hostname -s)" >> /etc/profile
# export SERVICE_INSTANCE_NAME=$(hostname -s)
#
#yum install -y ERICenmsgopendj_CXP9031570
#
## Set the envar to identify the server. opendj user does not exist until opendj RPMs are installed
#echo -e "\nexport SERVICE_INSTANCE_NAME= $(hostname -s)" >> /home/opendj/.bashrc
#echo -e "SERVICE_INSTANCE_NAME= $(hostname -s)" >> $OPENDJ_VARIABLES
#
#This needs to change
#sed -i "s/$(hostname)/$(hostname) ldap-local ldap-remote/g" /etc/hosts

#Remove exitsing certs if exits
rm -f /ericsson/tor/data/certificates/rootCA.key
rm -f /ericsson/tor/data/certificates/rootCA.pem
rm -f /ericsson/tor/data/certificates/rootCA.srl
rm -f /ericsson/tor/data/certificates/sso/ssoserverapache.crt
rm -f /ericsson/tor/data/certificates/sso/ssoserverapache.key
rm -f /ericsson/tor/data/certificates/sso/ssoserverapache.p12
rm -f /ericsson/tor/data/certificates/sso/ssoserverjboss.crt
rm -f /ericsson/tor/data/certificates/sso/ssoserverjboss.key
rm -f /ericsson/tor/data/certificates/sso/ssoserverjboss.p12
rm -f /ericsson/tor/data/idenmgmt/idmmysql_passkey
rm -f /ericsson/tor/data/idenmgmt/opendjrestartcomplete.txt
rm -f /ericsson/tor/data/idenmgmt/postgresql01_passkey
rm -f /ericsson/tor/data/idenmgmt/ssoldap_passkey
rm -f /ericsson/tor/data/idenmgmt/opendj_passkey
rm -f /ericsson/tor/data/idenmgmt/openidm_passkey
rm -f /ericsson/tor/data/idenmgmt/secadmin_passkey

#Install package
yum install -y ERICidenmgmtopendj_CXP9030738.noarch
##Add opendj to enm group
usermod -a -G enm opendj
#Update start script to remove NUMA reference
sed -i 's/$NUMA_VALUE su -c "${INSTALL_ROOT}\/bin\/start-ds --quiet" - opendj/su -c "${INSTALL_ROOT}\/bin\/start-ds --quiet" - opendj/g' /etc/init.d/opendj
#Reduce memory footprint
totalMem=`free -g | grep "Mem" | awk '{print $2}'`
echo ${totalMem}
case ${totalMem} in
  [0])
    xmx=256
    xms=256
    ;;
  *)
    xmx=512
    xms=512
    ;;
esac

echo "xmx=$xmx and xmx = $xms"
sed -i "s/-Xms[0-9]*m/-Xms${xms}m/g" /opt/ericsson/com.ericsson.oss.security/idenmgmt/opendj/bin/install_opendj.sh
sed -i "s/-Xmx[0-9]*m/-Xmx${xmx}m/g" /opt/ericsson/com.ericsson.oss.security/idenmgmt/opendj/bin/install_opendj.sh

#aws fixes
sed -i "s/opendj.*//g" /etc/security/limits.conf

sed -i "s/$(hostname)/$(hostname) ldap-local ldap-remote/g" /etc/hosts
service opendj start
chkconfig opendj on

# Activate replication using a single OpenDJ instance
#/opt/ericsson/com.ericsson.oss.security/idenmgmt/opendj/bin/config_opendj_replication.sh

#Tech DEBT, As openDJ does a quiet restart on install creating a file to ensure DJ is fully started for others to check
#touch /ericsson/tor/data/idenmgmt/opendjrestartcomplete.txt
