#!/bin/bash
if [ $# -eq 0 ]
  then
    tput setaf 2;echo "Usage: ./$0 <CHARTNAME> <CHART_TYPE>"
    echo
    echo "       <CHARTNAME> - Name of the charts for your application, this will also be the 
                     applicaitons serrvicename,image name identifier."
    echo "       <CHART_TYPE> - Either stateless or stateful"
    echo "           stateless - use starter templates for stateless application(Deployment K8s Object)."
    echo "           stateful - use starter templates for stateful application(StatefulSet K8s Object)."
    tput sgr0
    exit 1
fi

LOGTAG=HELMCHARTS
SCRIPT_DIR=$(dirname $0)
APP=$1
TYPE=$2

if [[ "$TYPE" != "stateless" && "$TYPE" != "stateful" ]]; then
  logger -s -t ${LOGTAG} "Error - Incorrect template type provided, require stateless or stateful"
  exit 1
fi
logger -s -t ${LOGTAG} "Removing existing $APP charts if exist"
if [ -d ${APP} ]; then
  rm -rf ${APP}
fi
logger -s -t ${LOGTAG} "Creating helm charts for app="$APP" and template type=$TYPE"
helm create ${APP} --starter=${TYPE}
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "Error - failed to create templates for $APP, exiting...."
  exit 1
fi

logger -s -t ${LOGTAG} "Check ${APP} helm charts for errors"
helm lint ${APP}
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "Error - helm lint ${APP} failed, exiting...."
  exit 1
else
  logger -s -t ${LOGTAG} "Chart lint for ${APP} Successful"
fi

logger -s -t ${LOGTAG} "Locally render charts to file ${APP}.output"
helm template ${APP} > ${APP}.output
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "Error - failed to render charts for $APP, exiting...."
  exit 1
else
  logger -s -t ${LOGTAG} "Default rendered output charts available at: $(pwd ${SCRIPT_DIR})/${APP}.output"
fi

logger -s -t ${LOGTAG} "These are default charts, any specific applicatins changes can be made to the
templates and can be viewed with command 'helm template ${APP}'"
