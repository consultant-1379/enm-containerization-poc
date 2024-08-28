FROM 213418823860.dkr.ecr.us-east-1.amazonaws.com/enmpoc1-registry:rhel6jboss

MAINTAINER de biys

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils openldap sqlite db4 db4-utils audit-libs libsemanage audit-libs ncurses ncurses-base ncurses-libs iptables.x86_64
RUN yum -y install pyOpenSSL-0.10-2.el6.x86_64 rsyslog iptables-ipv6.x86_64

COPY sso_workarounds.sh /var/tmp/sso_workarounds.sh
COPY sso_class.py /var/tmp/sso_class.py
COPY install_sso.py /var/tmp/install_sso.py
COPY gossiprouter.xsl /var/tmp/gossiprouter.xsl

RUN  mkdir -p /ericsson/enm/alex
RUN  mkdir -p /ericsson/batch
RUN  mkdir -p /home/shared
RUN  mkdir -p /ericsson/config_mgt
RUN  mkdir -p /ericsson/vmcrons
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

RUN ln -s /usr/java/default/bin/jar /usr/bin/jar

RUN rm -f /etc/yum.repos.d/*

COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/


EXPOSE 8080 9990 4447 9999 1636 7999 4320


