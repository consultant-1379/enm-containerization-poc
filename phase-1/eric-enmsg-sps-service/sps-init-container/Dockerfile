FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jbossconfig:latest
LABEL maintainer="Def Leppard"

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps && \
    mkdir -p /ericsson/config_mgt && \
    mkdir -p /ericsson/enm/sps_cliconf

RUN yum install -y ERICpostgresqljdbc_CXP9031176 \
    ERICserviceframework_CXP9031003 \
    ERICserviceframeworkmodule_CXP9031004 \
    ERICmodelserviceapi_CXP9030594 \
    ERICmodelservice_CXP9030595 \
    ERICpib_CXP9030194 \
    ERICpkimanagerapi_CXP9031871 \
    ERICpkicoreapi_CXP9031872 \
    ERICpkicore_CXP9031876 \
    ERICpkimanager_CXP9031873 \
    ERICcredentialmanagerservice_CXP9031868 \
    ERICkeyaccessproviderservice_CXP9032385 \
    ERICvaultloginmodule_CXP9036201 && \
    yum clean all

COPY --chown=jboss_user:jboss image_content/standalone-enm.xml /ericsson/3pp/jboss/standalone/configuration
COPY --chown=jboss_user:jboss image_content/jboss-as.conf /ericsson/3pp/jboss/
COPY --chown=jboss_user:jboss image_content/pre-stop/* /ericsson/3pp/jboss/bin/pre-stop/
COPY --chown=jboss_user:jboss image_content/post-start/* /ericsson/3pp/jboss/bin/post-start/
#COPY --chown=jboss_user:jboss image_content/pre-start/* /ericsson/3pp/jboss/bin/pre-start/
COPY image_content/sps_cliconf/* /ericsson/enm/sps_cliconf/


COPY image_content/sps_init_entrypoint.sh /
COPY image_content/spsCertificateCheck.sh /var/tmp
COPY image_content/postgres_key.pem /var/tmp
COPY image_content/sps_config.sh /var/tmp

RUN sed -i "9 a bash /var/tmp/sps_config.sh" /ericsson/3pp/jboss/entry_point.sh

ENTRYPOINT ["/sps_init_entrypoint.sh"]

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
