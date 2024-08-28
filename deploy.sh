#!/bin/bash
#source /home/eccdpoc/git/ENM-containerisation-POC/deploy_config
#HOME_DIR=/home/eccdpoc/git/ENM-containerisation-POC/phase-0
source /ericsson/eababub/ENM-containerisation-POC/deploy_config
GP_DIR=${HOME_DIR}/globalproperties/
#Create NFS Mount Claims
create_nfs_provisioner(){

        helm install ${HOME_DIR}/eric-nfs-client-provisioner/ --name nfs-$NAMESPACE --set nfs.server=$NFS_SERVER_IP --set nfs.path=$EXPORT_SHARE_DIR --set storageClass.name=$NFS_STORAGE_CLASS_NAME --namespace $NAMESPACE

}

create_nfs_claims(){
        NFS_CLAIMS_DIR=${HOME_DIR}/external-nfs-pv-pvc
        for file in $(ls ${NFS_CLAIMS_DIR});do

                sed -i.bak "s/storageClassName.*/storageClassName: \"$NFS_STORAGE_CLASS_NAME\"/g" ${NFS_CLAIMS_DIR}/$file
                kubectl create -f ${NFS_CLAIMS_DIR}/$file -n $NAMESPACE;

        done
}

install_applications(){

#APPS="eric-enmsg-neo4j"
#APPS="eric-enmsg-neo4j eric-enmsg-opendj eric-enmsg-modelserv eric-enmsg-httpd eric-enmsg-security-service eric-enmsg-sso eric-enmsg-postgres eric-enmsg-openidm eric-enmsg-jmsserver eric-enmsg-gossiprouter eric-enmsg-sps-service eric-enmsg-serviceregistry eric-enmsg-uiservice eric-enmsg-ha-proxy"

for APP in ${APPS};do
        if [[ ${APP} == *"neo4j"* ]] ;then

                kubectl create -f ${HOME_DIR}/$APP/*.yaml -n $NAMESPACE
                #core.persistentVolume.storageClass
                helm install --name graphdb-$NAMESPACE ${HOME_DIR}/$APP/helm/$APP --set core.persistentVolume.storageClass=$STORAGE_CLASS --namespace $NAMESPACE

        elif [[ ${APP} == *"serviceregistry"* ]]; then

                sed -i.bak -e "s/storageClassName.*/storageClassName: \"$STORAGE_CLASS\"/g" -e "s/-n.*default/-n $NAMESPACE/g" ${HOME_DIR}/$APP/*.yaml
                kubectl create -f ${HOME_DIR}/$APP --recursive -n  $NAMESPACE
        elif [[ ${APP} == *"httpd"* ]]; then

                sed -i.bak -e "s/enm-phase-0/$enm_launcher_hostname/g" -e "s/-n.*default/-n $NAMESPACE/g" ${HOME_DIR}/$APP/*.yaml
                kubectl create -f ${HOME_DIR}/$APP --recursive -n  $NAMESPACE
        else

                sed -i.bak -e "s/storageClassName.*/storageClassName: \"$STORAGE_CLASS\"/g" -e "s/-n.*default/-n $NAMESPACE/g" ${HOME_DIR}/$APP/*.yaml
                kubectl create -f ${HOME_DIR}/$APP --recursive -n $NAMESPACE
        fi
done

}

create_service_role(){

    INIT_CONTAINER=${HOME_DIR}/eric-enm-init-container
    for file in $(ls ${INIT_CONTAINER}/*.yaml);do

        kubectl create -f $file -n $NAMESPACE

    done

}

other_config(){
#TO BE DONE LATER

while true;do

 kubectl get pods | grep consul-0 | grep Running &&  kubectl exec consul-0 consul operator raft list-peers | grep leader
 if [ $? -eq 0 ];then
    kubectl exec consul-0 consul kv put enm/deployment/databases/neo4j/neo4j_dps_user_password "U2FsdGVkX1+J2hdySayWwRkWIlmCIaOmMb2nmcO41co="
    kubectl exec consul-0 consul kv put enm/deployment/databases/neo4j/neo4j_admin_user_password "U2FsdGVkX1/P9jBWu102gheAwRab6e3gevyXRPxPXCc="
    kubectl exec consul-0 consul kv put enm/deployment/databases/neo4j/neo4j_reader_user_password "U2FsdGVkX1+ybFosJuavTFVXWxbnrI5mrHiCJsH0s3s="
    kubectl exec consul-0 consul kv put enm/deployment/databases/neo4j/paseochair "LlD5I9YKSBwN1fFZvAX7Gg=="
 break;
 fi

done

}
create_global_properties(){
        GP_DIR=${HOME_DIR}/globalproperties

        sed -i.bak -e "s/<lb_external_port>/${lb_external_port}/g" -e "s/<enm_launcher_hostname>/${enm_launcher_hostname}/g" ${GP_DIR}/gpconfigmap.yaml
        sed -i.bak -e "s/<lb_external_port>/${lb_external_port}/g" -e "s/<enm_launcher_hostname>/${enm_launcher_hostname}/g" ${GP_DIR}/gpphysicalconfigmap.yaml
        kubectl create -f ${GP_DIR}/gpconfigmap.yaml
        kubectl create -f ${GP_DIR}/gpphysicalconfigmap.yaml

        /bin/cp -f ${GP_DIR}/gpconfigmap.yaml.bak ${GP_DIR}/gpconfigmap.yaml
        /bin/cp -f ${GP_DIR}/gpphysicalconfigmap.yaml.bak ${GP_DIR}/gpphysicalconfigmap.yaml

}

delete_bak_files(){
	find ${HOME_DIR} -name "*.bak" -type f -delete
}

create_nfs_provisioner
create_nfs_claims
create_global_properties
create_service_role
install_applications
other_config
#delete_bak_files
