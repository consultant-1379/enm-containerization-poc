#!/bin/bash
if [[ -z $@ ]];then
  APPS="base jboss"
else
  APPS="$@"
fi

#docker login
eval $(aws ecr get-login)

LOGTAG=IMAGEBUILD
SCRIPT_DIR=$(dirname $0)
MYHOME=$(cd $SCRIPT_DIR;cd ..;pwd)
REGISTRY="152254703525.dkr.ecr.eu-west-1.amazonaws.com/eirepoc1-registry"

cd $MYHOME
for APP in ${APPS}
do
APPDIR=${MYHOME}/${APP}
cd ${APPDIR}
logger -s -t ${LOGTAG} "docker build -t aws/rhel6${APP}java8 ."
docker build -t aws/rhel6${APP}java8 .
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "build failed for $APP, exiting...."
  exit 1
fi
logger -s -t ${LOGTAG} "docker tag aws/rhel6${APP}java8 ${REGISTRY}:rhel6${APP}java8"
docker tag aws/rhel6${APP}java8 ${REGISTRY}:rhel6${APP}java8
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "build failed for $APP exiting...."
  exit 1
fi
logger -s -t ${LOGTAG} "docker push ${REGISTRY}:rhel6${APP}java8"
docker push ${REGISTRY}:rhel6${APP}java8
if [ $? -ne 0 ];then
  logger -s -t ${LOGTAG} "image is $APP failed exiting...."
  exit 1
fi

cd ${MYHOME}
done
