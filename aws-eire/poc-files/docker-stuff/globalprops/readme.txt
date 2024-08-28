#Create/Update all ConfigMaps
kubectl apply -f yamls/ -R
#Create/Update Cloud
kubectl apply -f gpcloud.yaml
#Create/Update Physical
kubectl apply -f gpphysical.yaml
#Create/Update Cloud no gossip
kubectl apply -f gpcloudnogossip.yaml
