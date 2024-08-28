FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jbossconfig:latest
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/enm/dumps

RUN yum clean all
RUN yum install -y ERICserviceframework_CXP9031003
RUN yum install -y ERICmediationengineapi_CXP9031505
RUN yum install -y ERICpib_CXP9030194
RUN yum install -y ERICdpsruntimeimpl_CXP9030468
RUN yum install -y ERICpmmedcom_CXP9030511
RUN yum install -y ERICmediationresolverspi_CXP9031837
RUN yum install -y ERICdpsattributeresolver_CXP9031782
RUN yum install -y ERICtssresolver_CXP9031783
RUN yum install -y ERICconfigureattributeresolver_CXP9031862
RUN yum install -y ERICrequestattributeresolver_CXP9031861
RUN yum install -y ERICtpattributeresolver_CXP9034039
RUN yum install -y ERICftpjcaconnectorapi_CXP9031542
RUN yum install -y ERICftpjcaconnector_CXP9031543
RUN yum install -y ERICinventoryhandlercode_CXP9031351
RUN yum install -y ERICsubscriptioncreationhandlercode_CXP9031211
RUN yum install -y ERICinbounddpshandlercode_CXP9030732
RUN yum install -y ERICneconnmep_CXP9031217
RUN yum install -y ERICneconn_CXP9030958
RUN yum install -y ERICsubscriptionvalidationhandlercode_CXP9031216
RUN yum install -y ERICmscmhealthcheckcode_CXP9034516
RUN yum install -y ERICnotificationreceiverhandlercode_CXP9031204
RUN yum install -y ERICsyncnodemocihandlercode_CXP9030740
RUN yum install -y ERICcryptographyservice_CXP9031013
RUN yum install -y ERICnedmediationhandlers_CXP9032962
RUN yum install -y ERICsshhandler_CXP9030865
RUN yum install -y ERICcryptographyserviceapi_CXP9031014
RUN yum install -y ERICmocihandlercode_CXP9030423
RUN yum install -y ERICserviceframeworkmodule_CXP9031004
RUN yum install -y ERICmodelserviceapi_CXP9030594
RUN yum install -y ERICdpsruntimeapi_CXP9030469
RUN yum install -y ERICversantclient_CXP9030230
RUN yum install -y ERICmodelservice_CXP9030595
RUN yum install -y ERICcredentialmanagercli_CXP9031389
RUN yum install -y ERICupgradeindcppretrievemimhandlers_CXP9031725
RUN yum install -y ERICftphandlercode_CXP9030846
RUN yum install -y ERICsshcredentialsmanagerhandlercode_CXP9032068
RUN yum install -y ERICtransportapi_CXP9031610
RUN yum install -y ERICerbshchandlercode_CXP9032089
RUN yum install -y ERICcpphchandlers_CXP9033213
RUN yum install -y ERICmgwhandlers_CXP9032093
RUN yum install -y ERICcppsoftwaresynchandlercode_CXP9032505
RUN yum install -y ERICcppnetworkmodelretrievertool_CXP9032554
RUN yum install -y ERICnetworkmodelretrieverapi_CXP9032695
RUN yum install -y ERICnetworkmodelretrieverplugins_CXP9032875
RUN yum install -y ERICvisibroker_CXP9031180
RUN yum install -y ERICcmmediationcommonhandlers_CXP9032461
RUN yum install -y ERICsshtransportlibrary_CXP9031609
RUN yum install -y ERICsshjcaconnector_CXP9031462
RUN yum install -y ERICipaddresschangecpphandlers_CXP9033173
RUN yum install -y ERICvmcmhandlers_CXP9033506
RUN yum install -y ERICbscpocmediation_CXP9033386
RUN yum install -y ERICtransportcimnormalization_CXP9035508
RUN yum install -y ERICtransportcimnormalizationspi_CXP9035509
RUN yum install -y ERICsharedtcimmediationhandlers_CXP9035185
RUN yum install -y ERICtransportcimmediationhandler_CXP9034419
RUN yum install -y ERICminilinkoutdoortranscimnormplugin_CXP9036063
RUN yum install -y ERICrncikev2handlercode_CXP9036267
RUN yum install -y ERICshmcppmediationhandlers_CXP9035933

COPY image_content/ /var/tmp/
COPY image_content/jboss-as.conf /ericsson/3pp/jboss/
COPY image_content/jboss-as-remote-ejb.conf /ericsson/3pp/jboss/bin/
COPY image_content/standalone-enm.xml /ericsson/3pp/jboss/standalone/configuration/
COPY image_content/postinstall.sh /ericsson/3pp/jboss/bin/post-start/
COPY image_content/apply_default_blacklist.sh /ericsson/3pp/jboss/bin/post-start/

ENV SECURE_PORT=59010 UNSECURE_PORT=59001
RUN echo "JAVA_OPTS=\"\$JAVA_OPTS -Dcm_securePort=\$SECURE_PORT -Dcm_unsecurePort=\$UNSECURE_PORT\"" >> /ericsson/3pp/jboss/bin/standalone.conf

RUN sed -i "9 a bash /var/tmp/mscm_config.sh" /ericsson/3pp/jboss/entry_point.sh

RUN chown -R jboss_user:jboss /ericsson/3pp/jboss

RUN bash /var/tmp/update_ulimit_openfiles.sh

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
