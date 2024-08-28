FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jbossconfig
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps

COPY --from=armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-pib /ericsson/ /ericsson/ \
                                                                         /opt/ericsson/ /ericsson/

COPY --from=armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-ps /ericsson/ /ericsson/ \
                                                                         /opt/ericsson/ /ericsson/

COPY --from=armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-securitysvc /ericsson/ /ericsson/ \
                                                                         /opt/ericsson/ /ericsson/

COPY --from=armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-serviceframework /ericsson/ /ericsson/ \
                                                                         /opt/ericsson/ /ericsson/
#CONTENT FROM UISERV SERVICE GROUP
#COPY image_content/standalone-enm.xml /ericsson/3pp/jboss/standalone/configuration/
#COPY image_content/jboss-as.conf /ericsson/3pp/jboss/

#RUN chown -R jboss_user:jboss /ericsson/3pp/jboss/

ENV SDK_CLUSTER_ID="uiserv" \
    UI_PRES_SERVER="enm.athtem.eei.ericsson.se" \
    JBOSS_BIND_ADDRESS="0.0.0.0"

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
