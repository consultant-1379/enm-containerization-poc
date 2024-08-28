#!/bin/bash

service rsyslog start

#!/bin/bash
SCRIPT_NAME=$(basename ${0})
LOG_TAG="MODELS-$(hostname -s)"

models_vm_rpmdb="/ericsson/models/rpm"

# Copy RPM DB from Cinder volume to VM's RPM DB.
if [ -d $models_vm_rpmdb ]; then
    command cp -r $models_vm_rpmdb/* /var/lib/rpm/
    rm -f /var/lib/rpm/__db*
    rpm --rebuilddb
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

to_be_removed_rpms="ERICenmdeploymenttemplates_CXP9031758 ERICenmsgmodelserv_CXP9032926 ERICenmvolumesnapshotconfig_CXP9034427"
for i in $to_be_removed_rpms; do
    remove_rpm_including_any_dependencies "$i"
done

# Install the deployment templates so that the xml within it can be used to find the list of model rpms. This should be replaced with a simpler way to identify the models to use. Maybe a yum group install?
yum install -y ERICenmdeploymenttemplates_CXP9031758

# Remove the model RPM related modelling jars from MDT directory should any exist
/bin/rm -rf /var/opt/ericsson/ERICmodeldeployment/data/*

# Install the models mentioned in the Deployment Description XML
yum install -y `grep model-package -A1 /ericsson/deploymentDescriptions/10svc_4scp_enm_physical_production_dd.xml | grep name | awk -F\> '{print $2}' | awk -F\< '{print $1}' | xargs`

yum install -y ERICparametermanagementmodel_CXP9035856
yum install -y ERICenmsgmodelserv_CXP9032926

# Prepare the layout for model deployment.
bash /ericsson/modelserv/bin/create_modelRpm_deployment_layout.sh

# Backup the updated RPM DB under cinder volume mount
mkdir -p $models_vm_rpmdb
command cp -r /var/lib/rpm/* $models_vm_rpmdb

bash /etc/rc.local

