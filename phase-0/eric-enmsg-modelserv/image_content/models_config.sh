#!/bin/bash
if [ ! -L /ericsson/tor/data/global.properties ]; then /bin/ln -s /gp/global.properties /ericsson/tor/data/global.properties; fi
# Set the envar to identify the server.
service rsyslog start

models_vm_rpmdb="/ericsson/models/rpm"

# Copy RPM DB from Cinder volume to VM's RPM DB.
if [ -d $models_vm_rpmdb ]; then
  command cp -r $models_vm_rpmdb/* /var/lib/rpm/
  rm -f /var/lib/rpm/__db*
  run rpm --rebuilddb
fi

list_of_removed_rpms=[]
remove_rpm_including_any_dependencies(){
  dependencies=($(rpm -qR "$1" | grep 'ERIC\|EXTR'))
  if [ "${#dependencies[@]}" -eq 0 ]; then
      if [[ ! ${list_of_removed_rpms[*]} =~ $1 ]]; then
          if yum remove -y "$1" >/dev/null 2>&1; then
              list_of_removed_rpms+=("$1")
              return 0
          fi
      fi
  fi

  for rpm_name in "${dependencies[@]}"
  do
      if yum list installed "$rpm_name" >/dev/null 2>&1; then
          remove_rpm_including_any_dependencies "$rpm_name"
      fi
  done
}

to_be_removed_rpms="ERICenmdeploymenttemplates_CXP9031758 ERICenmsgmodelserv_CXP9032926"
for i in $to_be_removed_rpms; do
  remove_rpm_including_any_dependencies "$i"
done

# Install the deployment templates so that the xml within it can be used to find the list of model rpms. This should be replaced with a simpler way to identify the models to use. Maybe a yum group install?
yum install -y ERICenmdeploymenttemplates_CXP9031758

# Remove the model RPM related modelling jars from MDT directory should any exist
/bin/rm -rf /var/opt/ericsson/ERICmodeldeployment/data/*

# Install the models mentioned in the 4_svc_enm_physical_production_dd.xml
yum install -y `grep model-package -A1 /ericsson/deploymentDescriptions/6svc_3scp_2evt_enm_ipv6_physical_production_dd.xml | grep name | awk -F\> '{print $2}' | awk -F\< '{print $1}' | xargs`

yum install -y ERICparametermanagementmodel_CXP9035856
yum install -y ERICenmsgmodelserv_CXP9032926
sed -i '/$_CREATE_MODELRPM_LAYOUT $POST_INSTALL_DIR/i \  $_CONSUL kv put $DEPLOYMENT_STATUS "MDT_started_$(date)"' /ericsson/modelserv/bin/post_deployment_MDT.sh

rm -f /usr/lib/ocf/resource.d/monitor_Models_Service.sh
cp -f /var/tmp/monitor_modelserv.sh /usr/lib/ocf/resource.d/monitor_modelserv.sh
cp -f /var/tmp/MDT_healthcheck.sh /usr/lib/ocf/resource.d/MDT_healthcheck.sh


service vmmonitord start

# Prepare the layout for model deployment.
bash /ericsson/modelserv/bin/create_modelRpm_deployment_layout.sh

# Backup the updated RPM DB under cinder volume mount
mkdir -p $models_vm_rpmdb
command cp -r /var/lib/rpm/* $models_vm_rpmdb

# workaround to add Cgroups JVM options so memory is adhered to
sed -i.bak 's/-XX:+HeapDumpOnOutOfMemoryError/-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+HeapDumpOnOutOfMemoryError/g' /opt/ericsson/ERICmodeldeployment/scripts/modeldeployservice
# Start the model service
service modeldeployservice start

# WA - Start consul in models so can invoke post_deploy_MDT.sh thru consul watches
rm -f /etc/consul.d/agent/snapshot_watch.json
consul agent -advertise=$(hostname -i) -node=$(hostname) -retry-join=consul-0.consul.${NAMESPACE}.svc.cluster.local -retry-join=consul-1.consul.${NAMESPACE}.svc.cluster.local -retry-join=consul-2.consul.${NAMESPACE}.svc.cluster.local -config-dir=/etc/consul.d/agent/ -data-dir=/var/consul/ -syslog &

sed '/NEO4J_BOLT_HOST=$($_CONSUL members/a \        NEO4J_BOLT_HOST="graphdb-neo4j"' /opt/ericsson/ERICdpsupgrade/pdw/common_functions

bash /ericsson/modelserv/bin/invokeMDT.sh
if [ $? -eq 0 ]; then
  echo "MDT completed successfully" > /ericsson/modelserv/MDT_complete.result
else
  echo "MDT has failed" > /ericsson/modelserv/MDT_complete.result
fi
