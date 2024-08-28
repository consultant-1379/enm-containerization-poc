#!/bin/bash

nodes=(10.10.10.17 10.10.10.16 10.10.10.18 10.10.10.20 10.10.10.21 10.10.10.22)


for i in ${nodes[@]};do
    ssh $i bash -c "'
    echo "VAR"
    sudo chmod 777 /etc/hosts
    echo "131.160.200.103 enmk8s.athtem.eei.ericsson.se" >> /etc/hosts
    cat /etc/hosts
     '"
done

