FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jbossconfig
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps

RUN yum clean all
RUN yum install -y ERICserviceframework_CXP9031003 
RUN yum install -y ERICserviceframeworkmodule_CXP9031004 

