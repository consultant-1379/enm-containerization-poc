FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

RUN yum install -y ERICenmsggossiprouter_CXP9034239
RUN mkdir -p /ericsson/enm/dumps

COPY image_content/gossip_entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 12987 5093 5099 12001 12002 9990 8009 9999 8080 4447
