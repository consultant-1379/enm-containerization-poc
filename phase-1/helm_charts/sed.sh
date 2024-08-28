#!/bin/bash
name=$1

sed -i 's/^          //g' $name/appconfig/containerPorts.txt
sed -i 's/^    //g' $name/appconfig/servicePorts.txt
sed -i 's/^          //g' $name/appconfig/volumeMounts.txt
sed -i 's/^        //g' $name/appconfig/volumes.txt
