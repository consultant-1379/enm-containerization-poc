#FROM k8s-registry.eccd.local/rhel6jboss:green
FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/rhel6jbosspoc:latest
MAINTAINER dudderlads

###################################
# ENV VARIABLES
###################################
ARG ISO_VERSION
ENV ISO_VERSION=$ISO_VERSION
ARG GIT_COMMIT=unspecified
ARG BUILD_NUMBER=unspecified
ARG MAVEN_VERSION=unspecified

LABEL \
     iso_version=$ISO_VERSION \
     git_commit=$GIT_COMMIT \
     build_number=$BUILD_NUMBER
     maven_version=$MAVEN_VERSION

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /ericsson/enm/dumps && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment
#    rm -f /etc/yum.repos.d/*
#COPY image_content/repos.repo /etc/yum.repos.d/
COPY image_content/ERICenmsguiservice_CXP9031574*.rpm /var/tmp/
RUN yum install -y /var/tmp/ERICenmsguiservice_CXP9031574*.rpm
COPY image_content/check_service_availability.sh /var/tmp/
COPY image_content/rename_currentxml.sh /var/tmp/
COPY image_content/setup-neo4j-subsystem.sh /var/tmp/
COPY image_content/uiserv_config.sh /var/tmp/
