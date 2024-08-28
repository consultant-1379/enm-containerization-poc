FROM armdocker.rnd.ericsson.se/proj_bounded_application/base/jboss-as

RUN  groupadd jboss
RUN  useradd jboss_user -g jboss

COPY auto.enm /etc/auto.enm
COPY auto.master /etc/auto.master

COPY install_and_configure_httpd.sh /var/tmp/install_and_configure_httpd.sh

RUN yum install -y rsyslog nc.x86_64


#RUN yum install -y autofs
#RUN chkconfig --add autofs

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils audit-libs libsemanage audit-libs

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

RUN rm -f /etc/yum.repos.d/*

COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/

EXPOSE 80 443 8666 22 123 

#RUN yum install -y ERICenmsgsps_CXP9031956 
#RUN yum install -y ERICjbossconfig_CXP9031583 
