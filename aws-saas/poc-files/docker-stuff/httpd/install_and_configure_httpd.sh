#!/bin/bash

# Set up host file
source /ericsson/tor/data/global.properties
echo -e "${HAPROXY_SERVICE_HOST} sso.${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts
echo -e "${HAPROXY_SERVICE_HOST} ${UI_PRES_SERVER} iorfile.${UI_PRES_SERVER}" >> /etc/hosts


#define array of all RPMs
declare -a array=( "ERIClauncher_CXP9030204" "ERICenmsghttpd_CXP9031596"  "ERICidentitymgmt_CXP9030739" "ERICuserprofilemenu_CXP9031485" /
  "ERICsystemsecurityconfiguration_CXP9032530" "ERIClauncher_CXP9030204" "ERIClogviewer_CXP9030285" "ERICapplib_CXP9032593" "ERICupgradeindserviceui_CXP9031719" /
  "ERIChealthcheckui_CXP9032092" "ERICcli_CXP9030319" "ERICnetworkexplorer_CXP9030473" "ERICnetworkexplorerlib_CXP9031008" "ERICtopologybrowser_CXP9030753" /
   "ERICalarmcontroldisplaygui_CXP9031026" "ERICalarmseveritysummary_CXP9032372" "ERICalarmtyperanking_CXP9032352" "ERICnoderankingbyalarmcount_CXP9032076" /
   "ERICalarmtypesummary_CXP9032346" "ERICfmxgui_CXP9032509" "ERICshmui_CXP9030799" "ERICnetworkhealthmonitorclient_CXP9031434" "ERICnodemonitorapp_CXP9031781" /
   "ERICkpimanagementapp_CXP9031735" "ERICmultinodehealthmonitorapp_CXP9031838" "ERICnhmwidgets_CXP9031824" "ERICnetworkscopewidget_CXP9032438" /
   "ERICnetworkstatuswidget_CXP9032560" "ERICipnediscoveryui_CXP9032137" "ERICipsmcommonui_CXP9032160" /
   "ERICautoidmanagement_CXP9030493" "ERICnodecliui_CXP9032670" /
   "ERICcellmanagementgui_CXP9034319" "ERICvnflcmui_CXP9032422" "ERICrdesktopsessionmanagement_CXP9034162" /
   "ERICwinfiolui_CXP9032843" "vim" )

echo "starting rsyslog..."
service rsyslog start
echo "installing software..."

 for i in "${array[@]}"
      do
        yum install -y "$i"
      done

      sed -i "s/^Listen.*/Listen $(getent hosts $(hostname)| cut -d' ' -f1):80/g" /opt/ericsson/ERIChttpdconfig_CXP9031096/conf/httpd.conf.new
      sed -i "s/^Listen.*/Listen $(getent hosts $(hostname)| cut -d' ' -f1):443/g" /opt/ericsson/sso/etc/40_ftsso_main_kvm.conf
      sed -i "s/rm -rf/#rm -rf/g" /opt/ericsson/com.ericsson.nms.utilities/configure_httpd.sh

      sed -i "s/\${SEMANAGE/#\${SEMANAGE/g" /opt/ericsson/sso/bin/kvm_sso_policy_agent_install.sh
      sed -i "s/\${RESTORECON/#\${RESTORECON/g" /opt/ericsson/sso/bin/kvm_sso_policy_agent_install.sh
      mkdir -p /var/log/sso; chmod 777 /var/log/sso
