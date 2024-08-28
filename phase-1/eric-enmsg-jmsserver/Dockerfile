FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6jboss:latest
MAINTAINER dudderlads

#RUN mkdir -p /ericsson/3pp/jboss/bin/pre-start \
#RUN mkdir -p /ericsson/3pp/jboss/standalone/data 

ARG _IMAGE_CONTENT_=image_content
ARG _SCRIPTS_=$_IMAGE_CONTENT_/scripts
ARG _SCRIPTS_PRESTART=$_SCRIPTS_/prestart
ARG _RESOURCES_=$_IMAGE_CONTENT_/resources
ARG _TARGET_HORNETQ_UTILITIES=$_IMAGE_CONTENT_/hornetq-utility/target
ARG JBOSS_HOME=/ericsson/3pp/jboss
ARG JMS_LOG_DIR=/ericsson/jms/log
ARG JBOSS_MESSAGING_DATA_DIRECTORY=/ericsson/jms/data
ARG MODEL_DIR="/etc/opt/ericsson/ERICmodeldeployment"
ARG DATA_SHARE_DIR="/ericsson/tor/data"
ARG UTILITIES_DIR=$JBOSS_HOME/bin/utilities

#####################
# jmsconfig content
#####################
COPY $_SCRIPTS_/jvisualvm.sh $JBOSS_HOME/bin/jvisualvm.sh
COPY $_SCRIPTS_/printHornetQJournalDetails.sh $JBOSS_HOME/bin/printHornetQJournalDetails.sh
COPY $_SCRIPTS_/printHornetQPageDetails.sh $JBOSS_HOME/bin/printHornetQPageDetails.sh
COPY $_SCRIPTS_/standalone.sh $JBOSS_HOME/bin/standalone.sh
COPY $_SCRIPTS_/checkJournal.sh $JBOSS_HOME/bin/checkJournal.sh
COPY $_SCRIPTS_/journalStatus.sh $JBOSS_HOME/bin/journalStatus.sh
COPY $_SCRIPTS_/jmslogger $JBOSS_HOME/bin/jmslogger
COPY $_SCRIPTS_/utilities $JBOSS_HOME/bin
# post-start
COPY $_SCRIPTS_/poststart $JBOSS_HOME/bin/post-start
# healthcheck
COPY $_SCRIPTS_/healthcheck/jboss_healthcheck.sh /usr/lib/ocf/resource.d/
# pre-stop
COPY $_SCRIPTS_/prestop $JBOSS_HOME/bin/pre-stop
COPY $_RESOURCES_/jboss-as.conf $JBOSS_HOME
COPY $_RESOURCES_/bin/jboss-cli-logging.properties $JBOSS_HOME/bin/jboss-cli-logging.properties
COPY $_RESOURCES_/bin/jboss-cli.xml $JBOSS_HOME/bin/jboss-cli.xml
COPY $_RESOURCES_/bin/standalone.conf $JBOSS_HOME/bin/standalone.conf
COPY $_RESOURCES_/standalone/configuration $JBOSS_HOME/standalone/configuration/

COPY $_TARGET_HORNETQ_UTILITIES/hornetq-utility*.jar $JBOSS_HOME/bin/hornetq-utility.jar

# new container specific  scripts
COPY $_SCRIPTS_/entry_point.sh $JBOSS_HOME/entry_point.sh
COPY $_SCRIPTS_/container_post_start.sh $JBOSS_HOME/container_post_start.sh
COPY $_SCRIPTS_/container-jms-jboss  $JBOSS_HOME/container-jms-jboss
COPY $_SCRIPTS_/container_pre_stop.sh $JBOSS_HOME/container_pre_stop.sh

ENV JVM_CACERTS_STORE="/usr/java/default/jre/lib/security/cacerts" \
    JBOSS_USER="jboss_user" \
    JBOSS_GROUP="jboss" \
    JBOSS_HOME=$JBOSS_HOME \
    JBOSS_MODULES="$JBOSS_HOME/modules/system/layers/base" \
    JMS_LOG_DIR=$JMS_LOG_DIR \
    JBOSS_CONSOLE_LOG="$JMS_LOG_DIR/console.log" \
    JBOSS_SERVER_LOG="$JMS_LOG_DIR/server.log" \
    HQ_FATAL_EXCEPTION_LOG="$JMS_LOG_DIR/hqfatalexception.log" \
    JBOSS_MESSAGING_DATA_DIRECTORY=$JBOSS_MESSAGING_DATA_DIRECTORY \
    JOURNAL_DIRECTORY="$JBOSS_MESSAGING_DATA_DIRECTORY/journal/" \
    JOURNALS_MOVING_LOCK_FILE="$JBOSS_MESSAGING_DATA_DIRECTORY/journals.moving" \
    JBOSS_CONF="$JBOSS_HOME/jboss-as.conf" \
    EXT_MODULES="/opt/ericsson/jboss/modules" \
    JBOSS_PIDFILE="/var/run/jboss/jboss.pid" \
    JBOSS_LOCKFILE="/var/lock/subsys/jboss" \
    STOP_WAIT="30" \
    PRE_STOP_WAIT="30" \
    LOG_WAIT="5" \
    JBOSS_CONFIG="standalone.xml" \
    STANDALONE_CONF="$JBOSS_HOME/bin/standalone.conf" \
    JOURNAL_SCRIPT="$JBOSS_HOME/bin/journalStatus.sh" \
    MGT_USER="hqcluster" \
    MGT_PASSWORD="3ric550N" \
    UTILITIES_DIR=$UTILITIES_DIR \
    UTILITY_IF_FILE_EXISTS="$UTILITIES_DIR/ifFileExists.sh" \
    PRE_START_DIR="$JBOSS_HOME/bin/pre-start" \
    PRE_STOP_DIR="$JBOSS_HOME/bin/pre-stop" \
    POST_START_DIR="$JBOSS_HOME/bin/post-start" \
    PRE_STOP_DIR="$JBOSS_HOME/bin/pre-stop" \
    POST_STOP_DIR="$JBOSS_HOME/bin/post-stop" \
    JBOSS_SCRIPT="$JBOSS_HOME/bin/standalone.sh" \
    MODEL_DIR=$MODEL_DIR \
    MODEL_REPO="$MODEL_DIR/data/repo/modelrepo.xml" \
    MOD_CLUSTER_PORT="8666" \
    DATA_SHARE_DIR=$DATA_SHARE_DIR \
    ROOTCACERT_FILE="$DATA_SHARE_DIR/certificates/rootCA.pem" \
    ENM_FD_LIMIT_FILE="/etc/security/limits.d/99-enmlimits.conf" \
    # Needs to be removed..just needed for phase-0  integration   
    JMS_SERVER_RUNNING="$DATA_SHARE_DIR/jmsserver.running" 

####################
#jmsserver content
####################
COPY $_RESOURCES_/standalone-enm.xml $JBOSS_HOME/standalone/configuration/standalone-enm.xml
COPY $_RESOURCES_/jboss-as.conf $JBOSS_HOME/jboss-as.conf
#https://github.com/moby/moby/issues/37965
RUN true
COPY $_RESOURCES_/diverts/* $JBOSS_HOME/standalone/data/


COPY $_SCRIPTS_PRESTART $JBOSS_HOME/bin/pre-start 

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /ericsson/enm/dumps && \
    mkdir -p $JMS_LOG_DIR && \
    chown -R jboss_user:jboss $JMS_LOG_DIR && \
    rm /usr/lib/ocf/resource.d/nfs_mount_check_ocf.bsh && \
    sed -i '\/NICE=\/bin\/nice/d' /usr/lib/ocf/resource.d/oom_check_ocf.bsh && \
    sed -i 's/${NICE} -n -17//g' /usr/lib/ocf/resource.d/oom_check_ocf.bsh  && \
    chown -R jboss_user:jboss $JBOSS_HOME && \
    chmod -R 755 $JBOSS_HOME && \
    chmod -R 755 /usr/lib/ocf/resource.d  

ENTRYPOINT ["/ericsson/3pp/jboss/entry_point.sh"]

EXPOSE 12987 8080 9990 4447 9999 5445 37370 12987 53733 58629 5455

LABEL com.ericsson.product.number="CXP 903 7049"
LABEL com.ericsson.product.revision="R1A"
LABEL org.label-schema.name=eric-enmsg-jmsserver
LABEL org.label-schema.build-date=2019-02-05T09:56:00.87Z
LABEL org.label-schema.vcs-ref=583731c
LABEL org.label-schema.vendor=“Ericsson”
LABEL org.label-schema.version=1.0.1
LABEL org.label-schema.schema-version=“1.0.0-rc1”
