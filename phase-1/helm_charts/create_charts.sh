#!/bin/bash
# ********************************************************************
# Ericsson LMI                                    SCRIPT
# ********************************************************************
#
# (c) Ericsson LMI 2019 - All rights reserved.
#
# The copyright to the computer program(s) herein is the property
# of Ericsson LMI. The programs may be used and/or copied only with
# the written permission from Ericsson LMI or in accordance with the
# terms and conditions stipulated in the agreement/contract under
# which the program(s) have been supplied.
#
# ********************************************************************
# Name    : create_charts.sh
# Purpose : Automates creation of helm charts for application.
#
# Usage   : See usage function below.
#
# ********************************************************************
LOG_TAG="HELM_CHARTS"
TMP_FILE=/tmp/app.$$
TMP_DIR=/tmp/.$$
STS=
DEP=
# FUNCTIONS
# ---------
# ********************************************************************
# Function Name: info
# Description: prints a info message to rsyslog.
# Arguments: $* - Info message.
# Return: 0.
# ********************************************************************
info() {
  [ $# -eq 0 ] && { error "Function ${FUNCNAME[0]} requires atleast 1 argument"; exit 1; }
  logger -s -t ${LOG_TAG} -p user.notice "INFO ${SCRIPT_NAME}: $*"
}
export -f info

# ********************************************************************
# Function Name: warn
# Description: prints a warning message to rsyslog.
# Arguments: $* - Warning message.
# Return: 0.
# ********************************************************************
warn() {
  [ $# -eq 0 ] && { error "Function ${FUNCNAME[0]} requires atleast 1 argument"; exit 1; }
  logger -s -t ${LOG_TAG} -p warn.notice "WARN ${SCRIPT_NAME}: $*"
}
export -f warn

# ********************************************************************
# Function Name: error
# Description: prints a error message to rsyslog.
# Arguments: $* - Error message.
# Return: 0.
# ********************************************************************
error() {
  [ $# -eq 0 ] && { error "Function ${FUNCNAME[0]} requires atleast 1 argument"; exit 1; }
  logger -s -t ${LOG_TAG} -p user.err "ERROR ${SCRIPT_NAME}: $*"
  cleanup
  exit 1
}
export -f error

function usage()
{
   local _msg_="$@"

   local scriptname=$(basename $0)

cat<<-EOF

        Command Arguments

           -n, --name
               Chart Name. Mandatory.

           -s, --sts
               Application is installed as a Statefulset - manages stateful applications.

           -d, --dep
               Application is installed as a Deployment - manages stateless applications.

           -p, --persist <accessMode,size,mountpoint>
               Only to be used with Statefulsets. Enables persistent storage.
               accessMode = ReadWriteOnce,ReadOnlyMany,ReadWriteMany.
               size = xGi
               mountpoint = /ericsson/tmp

           -a, --svc <svc>
               Default Service name. Mandatory.

           -x, --extrasvc <svc1,svc2>
               Extra Services.

           -w, --wait <svc1,svc2>
               Add services that application is dependent on.

           -r, --requests <memory,cpu>
               Request resources for container.
               memory = xGi
               cpu=<x>m

           -l, --limits <memory,cpu>
               Limit resources on the container.
               memory = xGi
               cpu=<x>m

           -c, --cm <mountpath>
               Application Config Map.
               mountpoint = /ericsson/tmp

           -r, --recreate
               Recreate charts with previous config. Used when new starter templates delivered.

           -f, --force
               Delete previous chart directory if exists.

           -v, --privileged
               Privileged container. Should be avoided.

           -h, --help
               Display this usage.

        Examples:
        # Statefulset
        # $scriptname --sts --name eric-enmsg-test --svc testsvc --extrasvc test1svc,test2svc --wait cmserv,neo4j --persist ReadWriteOnce,60Gi,/ericsson/test --requests 6Gi --cm /ericsson/config

        # Deployment
        # $scriptname --dep --name eric-enmsg-test --svc testsvc --extrasvc test1svc,test2svc --wait cmserv,neo4j --limits 6Gi --cm /ericsson/config --force

        # Recreate
        # $scriptname --name eric-enmsg-test --recreate
EOF
   exit 1
}

# Called when script is executed with invalid arguments
function invalid_arguments() {
  local scriptname=$(basename $0)
  echo "Missing or invalid option(s):"
  echo "$@"
  echo "Try $scriptname --help for more information"
  error "Invalid options passed to script ($@) "
}

# Process the options and arguments passed to the script and export relevant variables
function process_arguments() {
  local short_args="vfusdhx:p:n:a:w:r:l:c:"
  local long_args="privileged,force,recreate,sts,dep,help,extrasvc:,persist:,name:,svc:,wait:,requests:,limits:,cm:"

  args=$(getopt -o $short_args -l $long_args -n "$0" -- "$@"  2>&1 )
  [[ $? -ne 0 ]] && invalid_arguments $( echo " $args"| head -1 )
  [[ $# -eq 0 ]] && invalid_arguments "No options provided"
  eval set -- "$args"

while true; do
  case "$1" in
     -n|--name)
        export NAME=$2 && echo NAME=$2 >> ${TMP_FILE}
        shift 2 ;;
     -s|--sts)
        export STS=true && echo STS=true >> ${TMP_FILE}
        shift ;;
     -d|--dep)
        export DEP=true && echo DEP=true >> ${TMP_FILE}
        shift ;;
     -a|--svc)
        export SVC=$2 && echo SVC=$2 >> ${TMP_FILE}
        shift 2 ;;
     -x|--extrasvc)
        export EXTRASVC=true && echo EXTRASVC=true >> ${TMP_FILE}
        export ESVC_LIST=$2 && echo ESVC_LIST=$2 >> ${TMP_FILE}
        shift 2 ;;
     -p|--persist)
        export PERSIST=true && echo PERSIST=true >> ${TMP_FILE}
        export PERSIST_LIST=$2 && echo PERSIST_LIST=$2 >> ${TMP_FILE}
        shift 2 ;;
     -w|--wait)
        export WAIT=true && echo WAIT=true >> ${TMP_FILE}
        export WAIT_LIST=$2 && echo WAIT_LIST=$2 >> ${TMP_FILE}
        shift 2 ;;
     -r|--requests)
        export REQUESTS=true && echo REQUESTS=true >> ${TMP_FILE}
        export REQUESTS_LIST=$2 && echo REQUESTS_LIST=$2 >> ${TMP_FILE}
        shift 2 ;;
     -l|--limits)
        export LIMITS=true && echo LIMITS=true >> ${TMP_FILE}
        export LIMITS_LIST=$2 && echo LIMITS_LIST=$2 >> ${TMP_FILE}
        shift 2 ;;
     -c|--cm)
        export CM=true && echo CM=true >> ${TMP_FILE}
        export MOUNTPOINT=$2 && echo MOUNTPOINT=$2 >> ${TMP_FILE}
        shift 2 ;;
     -u|--recreate)
        export RECREATE=true
        shift ;;
     -u|--recreate)
        export RECREATE=true
        shift ;;
     -f|--force)
        export FORCE=true
        shift ;;
     -v|--privileged)
        export PRIVILEGED=true && echo PRIVILEGED=true >> ${TMP_FILE}
        shift ;;
     -h|--help)
        usage
        exit 0 ;;
     --)
        shift
        break ;;
     *)
        echo BAD ARGUMENTS # perhaps error
        break ;;
  esac
done


# Ensure mandatory parameters are set
if [ "$RECREATE" != "true" ] ; then
  if [ "$STS" != "true" ] && [  "$DEP" != "true" ] ; then
    invalid_arguments "-d|--dep or -s|--sts must be set"
  fi

  if [ "$STS" = "true" ] && [  "$DEP" = "true" ] ; then
    invalid_arguments "Should only specify one of --sts or --dep"
  fi

  if [ "$DEP" = "true" ] && [  "$PERSIST" = "true" ] ; then
    invalid_arguments "-d|--dep should not have persistent volume"
  fi

  if [ "$REQUESTS" = "true" ] && [  "$LIMITS" = "true" ] ; then
    invalid_arguments "Should only specify one of --limits or --requests"
  fi

  if [ -z "$SVC" ] ; then
    invalid_arguments "-a | --svc must be specified with service name."
  fi
fi

if [ -z "$NAME" ] ; then
  invalid_arguments "-n | --name must be specified with a chart name."
fi

if [ "$RECREATE" = "true" ] && [  ! -f ${NAME}/appconfig/.appenv  ] ; then
  error "Can't use --recreate as previous args not stored"
fi

info "Arguments processed successfully"

return 0
}
function cleanup() {
rm -rf ${TMP_DIR}
rm -f ${TMP_FILE}
}

function create_helmchart() {

if [ -d ${NAME} ] ; then
  if [ "$RECREATE" = "true" ] ; then
    cp -rf ${NAME}/appconfig ${TMP_DIR}
    source ${TMP_DIR}/.appenv
    rm -rf ${NAME}
  elif [ "$FORCE" = "true" ] ; then
    cp -rf ${NAME}/appconfig ${TMP_DIR}
    rm -rf ${NAME}
  else
    error "${NAME} Directory already exists...exiting..."
  fi
fi

helm create --starter=enm $NAME
if [ $? -ne 0 ] ; then
  error "Error with helm create command... exiting..."
else
  info "helm create completed successfully"
fi

if [ "$DEP" = "true" ] ; then
  rm -f ${NAME}/templates/statefulset.yaml
  rm -f ${NAME}/templates/headless-service.yaml
  info "Templates set for Deployment"
fi

sed -i "s/SERVICENAME/${SVC}/" ${NAME}/values.yaml

if [ "$EXTRASVC" = "true" ] ; then
  IFS=',' read -r -a array <<<  ${ESVC_LIST}
  COUNT=${#array[@]}
  i=1
    while [ $i -le $COUNT ] ; do
      for svc in "${array[@]}" ; do
        cp ${NAME}/templates/svc.yaml ${NAME}/templates/${svc}.yaml
        sed -i "/service:/a \  name${i}: ${svc}" ${NAME}/values.yaml
        sed -i "s/name: {{ .Values.service.name }}/name: {{ .Values.service.name${i} }}/" ${NAME}/templates/${svc}.yaml
        (( i++ ))
    done
  done
  info "Extra services added to templates: ${ESVC_LIST}"
fi

if [ "$STS" = "true" ] ; then
  rm -f $NAME/templates/deployment.yaml
  rm -f $NAME/templates/svc.yaml
  info "Templates set for Statefulset"
fi

if [ "$WAIT" = "true" ] ; then
  sed -i '/waitInitContainer:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  sed -i "s/WAITSERVICE/${WAIT_LIST}/" ${NAME}/values.yaml
  if [[ ${WAIT_LIST} == *"neo4j"* ]]; then
    sed -i '/waitInitContainerEnv:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  fi
  info "Wait init container enabled to wait for svc : ${WAIT_LIST}"
fi

if [ "$PERSIST" = "true" ] ; then
  IFS=',' read -r -a array <<<  ${PERSIST_LIST}
  ACCESSMODE=${array[0]}
  SIZE=${array[1]}
  MOUNTPATH=${array[2]}
  sed -i '/persistentVolumeClaim:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  sed -i "s/ACCESSMODE/${ACCESSMODE}/" ${NAME}/values.yaml
  sed -i "s/SIZE/${SIZE}/" ${NAME}/values.yaml
  sed -i "s|MOUNTPATH|${MOUNTPATH}|" ${NAME}/values.yaml
  info "Persistent storage enabled"
fi

if [ "$REQUESTS" = "true" ] ; then
  IFS=',' read -r -a array <<<  ${REQUESTS_LIST}
  RMEM=${array[0]}
  RCPU=${array[1]}
  sed -i '/requests:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  sed -i "s/RMEM/${RMEM}/" ${NAME}/values.yaml
  sed -i "s/RCPU/${RCPU}/" ${NAME}/values.yaml
  info "Resource requests enabled"
fi

if [ "$LIMITS" = "true" ] ; then
  IFS=',' read -r -a array <<<  ${LIMITS_LIST}
  LMEM=${array[0]}
  LCPU=${array[1]}
  sed -i '/limits:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  sed -i "s/LMEM/${LMEM}/" ${NAME}/values.yaml
  sed -i "s/LCPU/${LCPU}/" ${NAME}/values.yaml
  info "Resource limits enabled"
fi

if [ "$CM" = "true" ] ; then
  sed -i '/configMaps:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  sed -i "s|MOUNTPOINT|${MOUNTPOINT}|" ${NAME}/values.yaml
  info "Config Map enabled"
fi

if [[ ${NAME} == *"httpd"* ]]; then
  sed -i '/ingress:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  info "ingress service set for httpd"
fi

if [[ ${NAME} == *"security-service"* ]]; then
  sed -i '/enmInitContainer:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  sed -i '/enmInitContainerEnv:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  info "ENM init container to create neo4j config enabled for security-service"
fi

if [ "$PRIVILEGED" = "true" ] ; then
  sed -i '/privileged:/{N;s/enabled:.*/enabled: true/}' ${NAME}/values.yaml
  info "Setting privileged container"
fi

# cleanup
if [ -d ${TMP_DIR} ] ; then
  info "Copying in previous appconfig files"
  rsync -azh ${TMP_DIR}/. ${NAME}/appconfig/
fi
if [ "$RECREATE" != "true" ] ; then
  cp -f ${TMP_FILE} ${NAME}/appconfig/.appenv
fi
cleanup

info "All functions completed successfully"
}

# Main
export SCRIPT_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}/" )/.." && pwd)"

process_arguments $@
if [ $? -ne 0 ] ; then
   exit 1
fi
create_helmchart
exit 0
