FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

RUN mkdir -p /ericsson/enm/dumps

RUN yum install -y ERICconsulconfig_CXP9033977

COPY image_content/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["consul"]

EXPOSE 12987 8500 8301 53 8300 80 443 8400 8443 8301 8302 8600
