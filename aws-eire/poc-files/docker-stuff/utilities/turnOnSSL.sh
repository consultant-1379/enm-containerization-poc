#/bin/bash

echo "modifying http.conf"
sed -i "s/#SSLProtocol T/SSLProtocol T/g" /etc/httpd/conf/httpd.conf
sed -i "s/#SSLHonorCipherOrder o/SSLHonorCipherOrder o/g" /etc/httpd/conf/httpd.conf

echo "modifying agent.conf"
/bin/cp -f  /opt/ericsson/sso/web_agents/apache22_agent/Agent_001/config/agent.conf.SECURE_WORKING /opt/ericsson/sso/web_agents/apache22_agent/Agent_001/config/agent.conf

echo "modifying 40_ftsso_main_kvm.conf"
/bin/cp /etc/httpd/conf.d/40_ftsso_main_kvm.conf.SECURE /etc/httpd/conf.d/40_ftsso_main_kvm.conf

echo "restarting httpd"
service httpd restart
