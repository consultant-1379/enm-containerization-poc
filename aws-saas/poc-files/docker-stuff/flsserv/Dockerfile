FROM 213418823860.dkr.ecr.us-east-1.amazonaws.com/enmpoc1-registry:rhel6jboss

MAINTAINER delads

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils openldap sqlite db4 db4-utils audit-libs libsemanage audit-libs ncurses ncurses-base ncurses-libs iptables.x86_64
RUN yum -y install pyOpenSSL-0.10-2.el6.x86_64 rsyslog iptables-ipv6.x86_64 openssh openssh-clients

RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/id_rsa

COPY postgres_key.pem  /root/.ssh/id_rsa

RUN chmod 700 /root/.ssh
RUN  chmod 600 /root/.ssh/id_rsa

RUN  mkdir -p /ericsson/batch
RUN  mkdir -p /ericsson/config_mgt
RUN  mkdir -p /ericsson/enm/dlms/history/data
RUN  mkdir -p /var/ericsson/ddc_data
RUN  mkdir -p /ericsson/tor/smrs
RUN  mkdir -p /ericsson/tor/data
RUN  mkdir -p /ericsson/custom
RUN  mkdir -p /ericsson/enm/dumps
RUN  mkdir -p /ericsson/tor/no_rollback
RUN  mkdir -p /etc/opt/ericsson/ERICmodeldeployment
RUN  mkdir -p /ericsson/pmic1
RUN  mkdir -p /ericsson/pmic2
RUN  mkdir -p /ericsson/symvol
RUN  mkdir -p /ericsson/configuration_management/UpgradeIndependence
RUN  mkdir -p /ericsson/netlog

RUN ln -s /usr/java/default/bin/jar /usr/bin/jar

RUN rm -f /etc/yum.repos.d/*

COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/
COPY flsserv_config.sh /var/tmp/
COPY setup-neo4j-subsystem.sh /var/tmp/
COPY check_service_availability.sh /var/tmp/
#COPY gossiprouter.xsl /var/tmp/

RUN groupmod -g 205 jboss
RUN usermod -u 308 jboss_user
RUN useradd -u 501 -g 205 enmadm
RUN groupmod -n enm jboss
RUN groupadd jboss -g 206
RUN groupmems -g jboss -a jboss_user
RUN groupmems -g jboss -a enmadm
RUN groupmems -g enm -a jboss_user
RUN groupmems -g enm -a enmadm
RUN chgrp enm /home
RUN chgrp enm /ericsson
RUN chmod 775 /home
RUN chmod 775 /ericsson

EXPOSE 8080 9990 4447 9999 1636 7999 4320 8085 8445

