FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jbossconfig
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps

RUN yum clean all
RUN yum install -y ERICpersistentobjectservice_CXP9031015
RUN yum install -y ERICtopologysearch_CXP9030474
RUN yum install -y ERICserviceframework_CXP9031003 
RUN yum install -y ERICpib_CXP9030194 
RUN yum install -y ERICserviceframeworkmodule_CXP9031004 
RUN yum install -y ERICmodelservice_CXP9030595 
RUN yum install -y ERICmodelserviceapi_CXP9030594 
RUN yum install -y ERICmodelinformationservice_CXP9031071
RUN yum install -y ERICtopologycollections_CXP9030498
RUN yum install -y ERICnetworkexplorerimport_CXP9034327
RUN yum install -y ERICaddnodeservice_CXP9034870
RUN yum install -y ERICcryptographyservice_CXP9031013
RUN yum install -y ERICcryptographyserviceapi_CXP9031014
RUN yum install -y ERICaddnoderest_CXP9034868
RUN yum install -y ERICdpsruntimeimpl_CXP9030468
RUN yum install -y ERICdpsruntimeapi_CXP9030469
RUN yum install -y ERICdpsmediationclient_CXP9031421
RUN yum install -y ERICmediationengineapi_CXP9031505
RUN yum install -y ERICcmeditcommon_CXP9035095
RUN yum install -y ERICversantclient_CXP9030230
RUN yum install -y ERICoverloadprotection_CXP9035626
RUN yum install -y postgresql92-postgresql



#CONTENT FROM NETEX SERVICE GROUP
COPY image_content/standalone-enm.xml /ericsson/3pp/jboss/standalone/configuration/
COPY image_content/jboss-as.conf /ericsson/3pp/jboss/
COPY image_content/jboss-as-remote-ejb.conf /ericsson/3pp/jboss/bin/
COPY image_content/overload-protection-config.json /ericsson/3pp/jboss/standalone/configuration/
COPY image_content/netex_eserviceref_cleanup.sh /ericsson/3pp/jboss/bin/pre-start
COPY image_content/netex_sfs_setup.sh /ericsson/3pp/jboss/bin/pre-start

RUN chown -R jboss_user:jboss /ericsson/3pp/jboss/

ENV SDK_CLUSTER_ID="netex"

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
