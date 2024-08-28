FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

RUN mkdir -p /ericsson/enm/dumps && \
    mkdir -p /ericsson/sentinel_lic

COPY image_content/sentinel_config.sh /var/tmp/

EXPOSE 12987 5093 5099
