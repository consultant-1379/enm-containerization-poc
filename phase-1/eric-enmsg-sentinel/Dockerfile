FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

RUN mkdir -p /ericsson/enm/dumps && \
    mkdir -p /ericsson/sentinel_lic
RUN yum install -y ERICenmsentinellicensemanager_CXP9033766 && \
    yum clean all

COPY image_content/sentinel_entrypoint.sh /entrypoint.sh

ENV LSERVRC=/ericsson/sentinel_lic/lservrc

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 12987 5093 5099
