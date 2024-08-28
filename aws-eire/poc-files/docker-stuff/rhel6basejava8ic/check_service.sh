#!/bin/bash
cacert="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
token="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

usage() { echo "Usage: $0 [-s service1,service2,service3,....\"] [-n namespace]" 1>&2; exit 1; }

while getopts ":s:n:" arg; do
    case "${arg}" in
        s)
            services=${OPTARG}
            ;;
        n)
            namespace=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${services}" ] || [ -z "${namespace}" ]; then
    usage
fi

IFS=","
for service in ${services}
do
  while true
  do
        curl --silent --cacert $cacert --header "Authorization: Bearer $token"  https://kubernetes.default.svc/api/v1/namespaces/${namespace}/endpoints/${service} | grep -qw "addresses"
        if [ $? -eq 0 ] ;then
          echo "$(date '+%Y-%m-%d %H:%M:%S') - Service is available : ${service}"
          break
        else
          echo "$(date '+%Y-%m-%d %H:%M:%S') - Waiting for service : ${service}"
          sleep 5
        fi
  done
done
