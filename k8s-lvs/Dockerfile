FROM registry.access.redhat.com/rhel7

ENV container docker
#RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
#systemd-tmpfiles-setup.service ] || rm -f $i; done); \
#rm -f /lib/systemd/system/multi-user.target.wants/*;\
#rm -f /etc/systemd/system/*.wants/*;\
#rm -f /lib/systemd/system/local-fs.target.wants/*; \
#rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
#rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
#rm -f /lib/systemd/system/basic.target.wants/*;\
#rm -f /lib/systemd/system/anaconda.target.wants/*;

COPY rhel7_yum.repo /etc/yum.repos.d/
COPY primary-backup.sh /var/tmp/
COPY keepalived.conf /etc/keepalived/
COPY conntrackd.conf /etc/conntrackd/
RUN yum install -y make gcc iptables libnl* popt* which vim keepalived conntrack-tools ipvsadm iproute  && yum clean all && rm -rf /var/cache/yum

#RUN curl https://git.kernel.org/pub/scm/utils/kernel/ipvsadm/ipvsadm.git/snapshot/ipvsadm-1.29.tar.gz -o ipvsadm-1.29.tar.gz && tar -xzf ipvsadm-1.29.tar.gz && cd ipvsadm-1.29 && make && make install


