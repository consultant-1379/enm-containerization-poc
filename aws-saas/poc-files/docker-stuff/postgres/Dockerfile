FROM 213418823860.dkr.ecr.us-east-1.amazonaws.com/enmpoc1-registry:rhel6base

MAINTAINER de lads

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils openldap sqlite db4 db4-utils audit-libs libsemanage audit-libs ncurses ncurses-base ncurses-libs iptables.x86_64
RUN yum -y install pyOpenSSL-0.10-2.el6.x86_64 rsyslog iptables-ipv6.x86_64 openssh openssh-clients openssh-server sudo

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

RUN echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA7oblllZBqhMiz9t4bA7ydstzr5ydRrtEbKgP9m00OpoVkw5mFLiTDOsQMeQPPpz+jRZy1CluVq8Ue4C7e1HbCpJArQGgF5vueDuOu4yGS4UAiU9syTYuWzr8POBoox6tPAb+cIn521GOLCPO+OyMTj6s13y9taExzoocZyLVrvohtfcCvZHFUxAN/DBj1L4sFKJfZRP4XvcwRZSZ06huYJTo98Gj6SNOQLTVYFXSI5uJK8G19a/2YYASPyQNlgpog0NvjCudwZO4JRyp6K6YO4mxkI2Eukcw6N9HLNaPe0EpaqBEIuTk0qqYk3A2UHzwVMzRXTB+ySKAotwX4itXpQ== root@nfs-server.novalocal'>>/home/cloud-user/.ssh/authorized_keys

RUN chown -R cloud-user:cloud-user /home/cloud-user/.ssh
RUN chown  cloud-user:cloud-user /home/cloud-user/.ssh/authorized_keys

RUN sed -i 's/# \%wheel/\%wheel/g' /etc/sudoers

RUN usermod -aG wheel cloud-user

RUN unlink /etc/localtime
RUN ln -s /usr/share/zoneinfo/UTC /etc/localtime

RUN rm -f /etc/yum.repos.d/*

COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/
COPY postinstall /var/tmp/
COPY sg_postinstall /var/tmp/
COPY postgres_config.sh /var/tmp/
COPY update_critical_size_threshold.sh /var/tmp/
RUN chmod +x /var/tmp/postinstall
RUN chmod +x /var/tmp/sg_postinstall

EXPOSE 12987 5432 22 33271

