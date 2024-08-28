#!/bin/bash
echo $1
if [ $1 = "serve" ];then
  BUILD_DIR=$(pwd)
  helm serve --repo-path $BUILD_DIR &
fi

for i in $(find ../ -name "Chart.yaml" | awk -F"/" '{print $2}'); do
if [[ $i != *"-integration"* ]]; then
  helm package ../$i
fi
done
helm dep up ../infra-integration
helm dep up ../stateless-integration
helm package ../infra-integration
helm package ../stateless-integration
