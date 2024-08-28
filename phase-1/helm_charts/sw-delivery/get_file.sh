#!/bin/bash


get_file(){

#stubbed for now
logger "Retrieving file"
logger "File retrieved"
echo "File retrieved..."
#wget https://arm.epk.ericsson.se/artifactory/proj-enm-helm/enm-installation/enm-installation-0.1.0.tgz 
echo "Warming up file-getter-ator..."
wget $1"/"$2 -O $2 
echo "File retrieved..."


}


get_file $1 $2
