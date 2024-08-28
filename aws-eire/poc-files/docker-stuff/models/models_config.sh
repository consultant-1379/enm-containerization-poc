#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
service rsyslog start

# Install the deployment templates so that the xml within it can be used to find the list of model rpms. This should be replaced with a simpler way to identify the models to use. Maybe a yum group install?
yum install -y ERICenmdeploymenttemplates_CXP9031758.noarch

# Install the models mentioned in the 4_svc_enm_physical_production_dd.xml
yum install -y `grep model-package -A1 /ericsson/deploymentDescriptions/6svc_3scp_2evt_enm_ipv6_physical_production_dd.xml | grep name | awk -F\> '{print $2}' | awk -F\< '{print $1}' | xargs`

yum install -y ERICenmsgmodelserv_CXP9032926

# Prepare the layout for model deployment.
bash /ericsson/modelserv/bin/create_modelRpm_deployment_layout.sh
# workaround to add Cgroups JVM options so memory is adhered to
sed -i.bak 's/-XX:+HeapDumpOnOutOfMemoryError/-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+HeapDumpOnOutOfMemoryError/g' /opt/ericsson/ERICmodeldeployment/scripts/modeldeployservice
# Start the model service
service modeldeployservice start

rm -f /usr/lib/ocf/resource.d/monitor_Models_Service.sh
/etc/init.d/vmmonitord start
bash /ericsson/modelserv/bin/invokeMDT.sh &
