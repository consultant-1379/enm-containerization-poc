#!/bin/bash -x

##########################
#
##########################
write(){

USER="$2"
KEY="$3"
FILE="$4"
URL="$1"

#echo "params...."
#echo "$USER $KEY $URL $ FILE"
#echo "running command....."

curl -s -u "$USER":"$KEY" -T "$FILE" "$URL/$FILE"

}


write "$@"


