FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps
RUN yum install -y sudo ERICconsulconfig_CXP9033977 bind-utils
COPY image_content/ /var/tmp/

EXPOSE 12987 22 44224 1636 37387 46797 1689 60442 4444 8989 8447 33537
