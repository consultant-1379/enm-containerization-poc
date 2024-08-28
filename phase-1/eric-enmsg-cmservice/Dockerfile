FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jbossconfig:latest
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/batch && \
    mkdir -p /ericsson/config_mgt && \
    mkdir -p /ericsson/enm/dumps && \
    mkdir -p /ericsson/cmserv/scripts

RUN yum install -y ERICserviceframework_CXP9031003 \
    ERICpib_CXP9030194 \
    ERICdpsruntimeimpl_CXP9030468 \
    ERICdpsmediationclient_CXP9031421 \
    ERICscripteng_CXP9030314 \
    ERICcmread_CXP9030316 \
    ERICcmwrite_CXP9030317 \
    ERICcmedit_CXP9030315 \
    ERICcmconfighandler_CXP9030948 \
    ERICcmconfigservice_CXP9030949 \
    ERICserviceframeworkmodule_CXP9031004 \
    ERICmodelserviceapi_CXP9030594 \
    ERICdpsruntimeapi_CXP9030469 \
    ERICversantclient_CXP9030230 \
    ERICmodelservice_CXP9030595 \
    ERICmediationengineapi_CXP9031505 \
    ERICneconn_CXP9030958 \
    ERICserverscripting_CXP9031931 \
    ERICpostgresqljdbc_CXP9031176 \
    postgresql \
    ERICupgradeindservice_CXP9031720 \
    ERIChcservice_CXP9032087 \
    ERICconfigurationrestapi_CXP9032302 \
    ERICcredentialmanagercli_CXP9031389 \
    ERICcmrollback_CXP9032596 \
    ERICcmhistorywriterapi_CXP9032970 \
    ERICcmhistorywriter_CXP9032971 \
    ERICclicollectionsavedsearchplugin_CXP9033882 \
    ERICcmeditcommon_CXP9035095 \
    ERICvaultloginmodule_CXP9036201 \
    ERICbatchprocessingmodule_CXP9031362 \
    openssh-clients && \
    yum clean all
####################
#TECH DEBT - Remove openssh-clients when Postgres config is sorted!
###################


COPY --chown=jboss_user:jboss image_content/standalone-enm.xml /ericsson/3pp/jboss/standalone/configuration/
COPY --chown=jboss_user:jboss image_content/jboss-as-remote-ejb.conf /ericsson/3pp/jboss/bin/
COPY --chown=jboss_user:jboss image_content/jboss-as.conf /ericsson/3pp/jboss/
COPY --chown=jboss_user:jboss image_content/check_config_schema_available.sh /ericsson/3pp/jboss/bin/pre-start/

COPY --chown=jboss_user:jboss image_content/other_stuff/ /var/tmp/

RUN sed -i "9 a bash /var/tmp/cmserv_config.sh" /ericsson/3pp/jboss/entry_point.sh

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
