FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jbossconfig
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps

RUN yum clean all
RUN yum install -y ERICsecuritysvc_CXP9023099
RUN yum install -y ERICps_CXP9030203 
RUN yum install -y ERICserviceframework_CXP9031003 
RUN yum install -y ERICpib_CXP9030194 
RUN yum install -y ERICserviceframeworkmodule_CXP9031004 
RUN yum install -y ERICmodelservice_CXP9030595 
RUN yum install -y ERICmodelserviceapi_CXP9030594 
RUN yum install -y ERIChelpsearch_CXP9032459

#CONTENT FROM UISERV SERVICE GROUP
COPY image_content/standalone-enm.xml /ericsson/3pp/jboss/standalone/configuration/
COPY image_content/jboss-as.conf /ericsson/3pp/jboss/

RUN chown -R jboss_user:jboss /ericsson/3pp/jboss/

ENV SDK_CLUSTER_ID="uiserv" \
    UI_PRES_SERVER="enm.athtem.eei.ericsson.se" \
    JBOSS_BIND_ADDRESS="0.0.0.0"

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
