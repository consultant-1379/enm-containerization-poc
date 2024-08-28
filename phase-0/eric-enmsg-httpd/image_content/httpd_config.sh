#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
service rsyslog start

yum install -y nc.x86_64
yum install -y bind-utils

source /ericsson/tor/data/global.properties
HAPROXY_POD_IP=$(dig +short haproxy-0.haproxy.default.svc.cluster.local)
echo -e "${HAPROXY_POD_IP} sso.${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts

yum install -y vim rsync

#install all ui content RPM from DD XML
yum install -y ERICenmdeploymenttemplates_CXP9031758 libxslt
yum install -y $(/usr/bin/xsltproc /var/tmp/httpd-vm-packages.xsl /ericsson/deploymentDescriptions/6svc_3scp_2evt_enm_ipv6_physical_production_dd.xml)

sed -i "s/^Listen.*/Listen $(getent hosts $(hostname)| cut -d' ' -f1):80/g" /opt/ericsson/ERIChttpdconfig_CXP9031096/conf/httpd.conf.new
sed -i "s/^Listen.*/Listen $(getent hosts $(hostname)| cut -d' ' -f1):443/g" /opt/ericsson/sso/etc/40_ftsso_main_kvm.conf
sed -i "s/rm -rf/#rm -rf/g" /opt/ericsson/com.ericsson.nms.utilities/configure_httpd.sh

sed -i "s/\${SEMANAGE/#\${SEMANAGE/g" /opt/ericsson/sso/bin/kvm_sso_policy_agent_install.sh
sed -i "s/\${RESTORECON/#\${RESTORECON/g" /opt/ericsson/sso/bin/kvm_sso_policy_agent_install.sh
mkdir -p /var/log/sso; chmod 777 /var/log/sso
#copy in workaround healthchech script
cp /var/tmp/httpd-lsb-monitor.bsh /usr/lib/ocf/resource.d/httpd-lsb-monitor.bsh
logger "starting service"
/etc/init.d/vmmonitord start
/etc/init.d/httpd-enm start
echo "* * * * * root bash /var/tmp/check_haproxy_ip.sh > /dev/null 2>&1" > /etc/cron.d/ipcheck
/etc/init.d/crond start
