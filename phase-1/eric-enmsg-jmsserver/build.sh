#!/bin/bash
set -x
_BUILD_DATE=$(date --utc +%FT%T.%2NZ)
readonly _NEW_BUILD_DATE_PATTERN="LABEL org.label-schema.build-date=${_BUILD_DATE}"
readonly _BUILD_DATE_PATTERN="LABEL org.label-schema.build-date"

_VCS_REF=$(git rev-parse --short HEAD)
readonly _NEW_VCS_REF_PATTERN="LABEL org.label-schema.vcs-ref=${_VCS_REF}"
readonly _VCS_REF_PATTERN="LABEL org.label-schema.vcs-ref"

_VERSION=$(cat VERSION_PREFIX)
readonly _NEW_VERSION_PATTERN="LABEL org.label-schema.version=${_VERSION}"
readonly _VERSION_PATTERN="LABEL org.label-schema.version"

function line_replace() {
    find_pattern=$1
    replace_pattern=$2
    file_name=$3
    sed -i "/${find_pattern}/c\\${replace_pattern}" ${file_name}
}


cd image_content/hornetq-utility
mvn clean install
cd ../../


line_replace "${_BUILD_DATE_PATTERN}" "${_NEW_BUILD_DATE_PATTERN}" "Dockerfile"
line_replace "${_VCS_REF_PATTERN}" "${_NEW_VCS_REF_PATTERN}" "Dockerfile"
line_replace "${_VERSION_PATTERN}" "${_NEW_VERSION_PATTERN}" "Dockerfile"



docker build --no-cache -t eric-enmsg-jmsserver:$_VERSION .

