FROM 152254703525.dkr.ecr.eu-west-1.amazonaws.com/eirepoc1-registry:rhel6basejava8

MAINTAINER de lads

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils openldap sqlite db4 db4-utils audit-libs libsemanage audit-libs ncurses ncurses-base ncurses-libs iptables.x86_64
RUN yum -y install pyOpenSSL-0.10-2.el6.x86_64 iptables-ipv6.x86_64 openssh openssh-clients openssh-server sudo

RUN mkdir /ericsson
RUN groupadd -r jboss && useradd --no-log-init -r -g jboss jboss_user
RUN groupadd cloud-user -g 500
RUN useradd -u 500 -g 500 cloud-user
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

RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/id_rsa
RUN mkdir -p /home/cloud-user/.ssh

RUN chmod 700 /root/.ssh
RUN chmod 700 /home/cloud-user/.ssh
RUN  chmod 600 /root/.ssh/id_rsa

RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/UTC /etc/localtime

RUN rm -f /etc/yum.repos.d/*

COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/
COPY configure-sentinel.sh /var/tmp/
RUN chmod +x /var/tmp/configure-sentinel.sh

EXPOSE 12987 22 5093 5099 

