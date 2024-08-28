FROM registry.access.redhat.com/rhel6/rhel:6.10
MAINTAINER dudderlads

COPY image_content/EXTRlitprsyslogelasticsearch_CXP9032173-1.1.5.rpm /var/tmp/

COPY image_content/yum.repos.d/ /etc/yum.repos.d/
COPY image_content/ERIClitpvmmonitord_CXP9031644-1.0.34.rpm /var/tmp/

RUN yum update -y && \
        yum install -y tar ERICenmconfiguration_CXP9031455 EXTRserverjre_CXP9035480 /var/tmp/EXTRlitprsyslogelasticsearch_CXP9032173-1.1.5.rpm /var/tmp/ERIClitpvmmonitord_CXP9031644-1.0.34.rpm && \
        yum clean all && \
        rm -f /etc/yum.repos.d/litp.repo /var/tmp/ERIClitpvmmonitord_CXP9031644-1.0.34.rpm

RUN groupadd -g 205 enm && \
        useradd -genm -d /home/enmadm enmadm && \
        useradd -genm -u 308 -d /home/jboss_user jboss_user && \
        groupadd -g 500 cloud-user && \
        useradd -g cloud-user -d /home/cloud-user cloud-user && \
        groupmems -g cloud-user -a cloud-user && \
        groupmems -g enm -a jboss_user && \
        groupmems -g enm -a enmadm && \
        chgrp enm /home && \
        chmod 775 /home && \
        mkdir /ericsson && \
        chgrp enm /ericsson && \
        chmod 775 /ericsson && \
        groupadd -g 206 jboss && \
        groupmems -g jboss -a jboss_user && \
        groupmems -g jboss -a enmadm

ENV JAVA_HOME=/usr/java/latest
ENV PATH=$PATH:$JAVA_HOME/bin
ENV PATH=$PATH:/sbin
ENV PATH=$PATH:/usr/sbin

COPY image_content/rsyslog.d/* /etc/rsyslog.d/
COPY image_content/limits.d/* /etc/security/limits.d/
RUN sed -i '$ i\*               -       nofile          10240' /etc/security/limits.conf && \
        sed -i '$ i\*               -       nproc           10240' /etc/security/limits.conf && \
        sed -i 's/1024/10240/g' /etc/security/limits.d/90-nproc.conf && \
        mkdir /var/log/sso && \
        rm -f /usr/lib/ocf/resource.d/cloud_init_ocf.sh && \
        service rsyslog stop && \
        service vmmonitord stop
