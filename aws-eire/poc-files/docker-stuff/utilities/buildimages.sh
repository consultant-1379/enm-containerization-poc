#!/bin/bash
if [[ -z $@ ]];then
  APPS="accesscontrol cmserv haproxy_sts impexpserv medrouter mscm opendj sentinel sso uiserv flsserv gossip-remoting jms openidm postgres secserv httpd lcmserv netex  pkiraserv sps supervc wpserv consul eventbasedclient medrouter models pmrouterpolicy fmalarmprocessing fmserv pmserv mspm msfm"
else
  APPS="$@"
fi

#docker login
eval $(aws ecr get-login)

LOGTAG=IMAGEBUILD
SCRIPT_DIR=$(dirname $0)
MYHOME=$(cd $SCRIPT_DIR;cd ..;pwd)
#MYHOME="/ericsson/mcaw/ENM-containerisation-POC/aws-eire/poc-files/docker-stuff"
REGISTRY="152254703525.dkr.ecr.eu-west-1.amazonaws.com/eirepoc1-registry"

cd $MYHOME
for APP in ${APPS}
do
#APPDIR=$(dirname $(find ${MYHOME} -name ${APP}.yaml))
APPDIR=${MYHOME}/${APP}
cd ${APPDIR}
if [ ${APP} == "gossiprouter" ] ;then
  APP=gossip-remoting
fi
if [ ${APP} == "generic-neo4j-service" ] ;then
  APP=cyphershell
fi
TAG=$(grep "image:" ${APP}.yaml  | awk -F":" '{print $3}')
logger  -t ${LOGTAG} "Building docker image for $APP"
logger -s -t ${LOGTAG} "docker build -t aws/${TAG} ."
docker build -t aws/${TAG} .
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "build failed for $APP, exiting...."
  exit 1
fi
logger -s -t ${LOGTAG} "docker tag aws/${TAG} ${REGISTRY}:${TAG}"
docker tag aws/${TAG} ${REGISTRY}:${TAG}
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "build failed for $APP exiting...."
  exit 1
fi
logger -s -t ${LOGTAG} "docker push ${REGISTRY}:${TAG}"
docker push ${REGISTRY}:${TAG}
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "image is $APP failed exiting...."
  exit 1
fi

cd ${MYHOME}
done
