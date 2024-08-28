#!/bin/bash
#HELM delete
source /ericsson/eshanco/cloudnative/ENM-containerisation-POC/deploy_config

helm delete --purge graphdb-$NAMESPACE
for i in $(kubectl get deployments | grep -v NAME | grep -v enm1 |  awk '{print $1}'); do kubectl delete deployment  $i; done

for i in $(kubectl get sts | grep -v NAME |  awk '{print $1}'); do kubectl delete sts  $i; done
#DELETE SERVICES

for svc in $(kubectl get svc | grep -v NAME |  awk '{print $1}'); do kubectl delete svc  $svc; done


#DELET ING
for i in $(kubectl get ing | grep -v NAME |  awk '{print $1}'); do kubectl delete ing  $i; done


for i in $(kubectl get cm | grep -v NAME |  awk '{print $1}'); do kubectl delete cm  $i; done

#DELET PVC

for pvc in $(kubectl get pvc | grep -v NAME |  awk '{print $1}'); do kubectl delete pvc  $pvc; done

kubectl delete role role-read-services

kubectl delete  rolebindings role-read-services-binding

helm delete nfs-$NAMESPACE --purge
