FROM dockerregistry:5000/rhel6

MAINTAINER Abdul

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils openldap sqlite db4 db4-utils audit-libs libsemanage audit-libs ncurses ncurses-base ncurses-libs iptables.x86_64
RUN yum -y install pyOpenSSL-0.10-2.el6.x86_64 rsyslog iptables-ipv6.x86_64 openssh openssh-clients


RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/UTC /etc/localtime

RUN rm -f /etc/yum.repos.d/*

COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/
COPY consul /usr/bin/

RUN groupadd consul && \
    useradd --no-log-init -r -g consul consul
RUN mkdir -p /ericsson/consul/data && \
    mkdir -p /ericsson/consul/config && \
    chown -R consul:consul /ericsson

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["consul"]

EXPOSE 12987 8500 8301 53 8300 80 443 8400 8443 8301 8302 8600

