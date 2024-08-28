FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /ericsson/enm/dumps

COPY image_content/ /var/tmp/

EXPOSE 12987 5432 22 33271
