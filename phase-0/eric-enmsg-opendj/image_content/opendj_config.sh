#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
service rsyslog start

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
yum install -y ERICidenmgmtopendj_CXP9030738 procmail vim
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
sed -i "s/OPENDJHOST1=.*/OPENDJHOST1=\"opendj\"/g" /opt/ericsson/com.ericsson.oss.security/idenmgmt/opendj/bin/install_opendj.sh

#aws fixes
rm -rf /etc/security/limits.d/opendj_custom.conf
sed -i "s/opendj.*//g" /etc/security/limits.conf

# fix [root@opendj-0 /]# su - opendj could not open session
sed -i 's/open/#&/' /etc/security/limits.d/opendj_custom.conf

/etc/init.d/vmmonitord start
service opendj start
