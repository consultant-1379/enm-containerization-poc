FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest

RUN yumdownloader ERICneo4jserverextension_CXP9032727
RUN rpm2cpio ERICneo4jserverextension_CXP9032727* | cpio -idmv

