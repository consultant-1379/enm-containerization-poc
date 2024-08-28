#!/bin/bash
#################################################
# POC Coce for SWGW integration
# NOT SHELLCHECKED YET
#################################################

FILE=""
SWGW_URL=""
HELM_URL=""
REGISTRY=""
TAG=UNDEFINED
HELP=FALSE
IMAGE_SWGW_URLS=""
LOG_TAG="SWGW_CLIENT"
OVERWRITE=FALSE

###################
# parse arguments
###################
parse_args(){

if ! OPTS=$(getopt -o f:s:r:t:hz:u:k:o --long file:,swgwurl:,registry:,tag:,help,helmurl:,helmuser:,helmkey:,overwrite -n 'parse-options' -- "$@");
then
    echo ${LOG_TAG} "Failed parsing options." >&2 ; exit 1 ; 
fi

eval set -- "$OPTS"

while true; do
  case "$1" in
    -f | --file ) FILE=$2; shift; shift;;
    -s | --swgwurl )  SWGW_URL=$2; shift; shift;;
    -z | --helmurl )  HELM_URL=$2; shift; shift;;
    -u | --helmuser )  HELM_USER=$2; shift; shift;;
    -k | --helmkey )  HELM_KEY=$2; shift; shift;;
    -r | --registry ) REGISTRY=$2; shift; shift;;
    -t | --tag ) TAG="$2"; shift; shift ;;
    -h | --help ) HELP=true; shift;;
    -o | --overwrite ) OVERWRITE=TRUE; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


if [ -z "${FILE}" ] || [ -z "${SWGW_URL}" ] || [ -z "${REGISTRY}" ] || [ -z "${TAG}" ] || [ -z "${HELM_URL}" ] ; then
    usage
fi



}

##################
# Prints Usage
##################
usage(){
printf "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
        \nDESCRIPTION: Retrieves a helm file from software gateway and interrogates it for required images.\nIt pulls those images,tags them with destination regustry and and pushes to docker registry
        \n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
printf "\nUsage: $0 [OPTIONS]\n[-f |--file <filename>] \n[-s |--swgwurl <software gateway url>] \n[-z |--helmurl <helm repo url>] \n[-u |--helmuser <user for helm repo>] \n[-k |--helmkey <helm security key>] \n[-r |--repo <docker registry> Image will be pushed to this registry and auto tagged with this value e.g. "registry.com:5000"] \n[-t |--tag <tag> OPTIONAL PARAMETER TO OVERRIDE DEFAULT TAG. UNSUPPORTED. IMAGE WILL BE TAGGED WITH DOCKER REGISTRY] \n[-h| --help prints usage]
\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n

Example Command:\n ./retrieve_software.sh -f enm-integration-0.1.0.tgz -s https://arm.epk.ericsson.se/artifactory/proj-enm-helm/stateless-integration -r registry:5000  -z https://arm.epk.ericsson.se/artifactory/proj-enm-helm-local/eric-enm -u ebrigun -k AABBHHY5buxJj6b224mBqZCyS92pHbxpVAuufr2WfDroy51TBvRsYGNfqDERerfggg

\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" 1>&2; exit 1;
}
get_file(){

source get_file.sh $1 $2
}



#############################################################
# Create an array of all the images from zipped helm chart(s)
##############################################################
run_helm_command(){

mapfile -t IMAGE_SWGW_URLS < <(./helm_command.sh $1)

}

######################################################
# tag each image and push to defined docker registry
######################################################
pull_tag_and_push(){

 for i in "${IMAGE_SWGW_URLS[@]}"
 do
    printf "\n"
    echo "${LOG_TAG} Processing remote image: ${i}"
    trimmed=$(trim "${i}")
    #echo $trimmed
    dockerimage=$(extract_image_name "$trimmed")
    #echo "docker image is $dockerimage"
    if image_exists "$REGISTRY/$dockerimage";then
      echo "${LOG_TAG} Image: "$REGISTRY/$dockerimage" already exists, nothing to do"
      #echo "successfully exited as no work to do"
    else
      docker pull "$trimmed"
      #dockerimage=$(extract_image_name "$trimmed")
      echo "${LOG_TAG} docker image is:$dockerimage"
      echo "${LOG_TAG} tagging $trimmed $REGISTRY/$dockerimage"
      docker tag "${trimmed}" "$REGISTRY/$dockerimage"
      echo "${LOG_TAG} pushing $REGISTRY/$dockerimage"
      docker push "$REGISTRY/$dockerimage"
    fi

 done
}

#############################
# write tar.gz to helm repo
############################
write_to_helm(){
 echo "${LOG_TAG} Writing helm chart(s) to local repo"
 source write_to_helm.sh $HELM_URL $HELM_USER $HELM_KEY $FILE #> /dev/null

}

###############################
# trim leading white space
##############################
trim(){
echo "$1" | awk '{gsub(/^ +| +$/,"")} {print $0}'

}

####################################################################################
# Extract image name and version from supplied string
# e.g. parse eric-neo4j-dps-initclient:latest FROM
# armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-neo4j-dps-initclient:latest
####################################################################################
extract_image_name(){


echo ${LOG_TAG} "$1" | awk -F "/" '{print $NF}'

}

image_exists(){
 
 if [ "$OVERWRITE" = "TRUE" ]; then
   echo "OVERWRITE: $OVERWRITE"
   return 1
 else
   echo ${LOG_TAG} checking registry for "$1"
   docker image inspect "$1" > /dev/null
 fi




}


parse_args "$@"
get_file "$SWGW_URL" "$FILE"
run_helm_command "$FILE"
pull_tag_and_push
write_to_helm
###########################################
###########################################
