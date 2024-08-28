FROM 152254703525.dkr.ecr.eu-west-1.amazonaws.com/eirepoc1-registry:rhel6basejava8

MAINTAINER Brian

RUN yum -y downgrade elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils openldap sqlite db4 db4-utils audit-libs libsemanage audit-libs ncurses ncurses-base ncurses-libs iptables.x86_64
RUN yum -y install pyOpenSSL-0.10-2.el6.x86_64 iptables-ipv6.x86_64

RUN yum install -y dos2unix

RUN  mkdir -p /var/ericsson/ddc_data
RUN  mkdir -p /ericsson/tor/data
RUN  mkdir -p /ericsson/enm/dumps
RUN  mkdir -p /ericsson/tor/no_rollback


RUN rm -f /etc/yum.repos.d/*

COPY enm.repo_static /etc/yum.repos.d/enm.repo
COPY rhel6.repo_static /etc/yum.repos.d/rhel6.repo
COPY rhel6_updates.repo_static /etc/yum.repos.d/rhel6_updates.repo

RUN chmod 775 /home
RUN chmod 775 /ericsson


COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/

COPY gossip_entrypoint.sh /entrypoint.sh

RUN dos2unix /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080 9990 4447 9999 1636 7999 4320 8085 8445 12001 12002




