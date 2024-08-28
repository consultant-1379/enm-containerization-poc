FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-httpd-sidecar:test
MAINTAINER dudderlads

RUN yum clean all
RUN yum install -y ERIClauncher_CXP9030204
RUN yum install -y ERICuserprofilemenu_CXP9031485

COPY 40_ftsso_main_kvm.conf /opt/ericsson/sso/etc/40_ftsso_main_kvm.conf

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445 80 443
