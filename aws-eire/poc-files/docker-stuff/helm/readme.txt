bash helm.sh
kubectl create serviceaccount tiller --namespace kube-system
kubectl create -f rbac-config.yaml
helm init --service-account tiller
