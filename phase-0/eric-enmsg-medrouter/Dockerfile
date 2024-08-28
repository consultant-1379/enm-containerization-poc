FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jboss:latest
MAINTAINER dudderlads
RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps

COPY image_content/ /var/tmp/

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
