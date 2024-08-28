#!/bin/bash

#echo "file to get" "$1"
#helm template enm-integration-0.1.0.tgz  | grep "image:" |tr -dc | sort| uniq | awk -F "image:" '{print $2}'

template_command(){
 #echo "extracting urls from template...."
 helm template $1  | grep "image:" | sort| uniq | awk -F "image:" '{print $2}'
}


template_command $1

