FROM registry.access.redhat.com/rhel6/rhel:latest
MAINTAINER dudderlads
RUN touch /etc/yum.repos.d/cifwk.repo && \
        touch /etc/yum.repos.d/rhel.repo && \
        touch /etc/yum.repos.d/patches.repo && \
        touch /etc/yum.repos.d/dynamic.repo && \
        echo -e "[dynamic]\nname=Dynamic Repository\nbaseurl=https://cifwk-oss.lmera.ericsson.se/static/dynamicRepos/rhel-x86_64-server-rh-common-6\nenabled=1\ngpgcheck=0" >> /etc/yum.repos.d/dynamic.repo && \
        echo -e "[cifwkrepo]\nname=Cifwk Repository\nbaseurl=https://cifwk-oss.lmera.ericsson.se/static/staticRepos/ENM/latest\nenabled=1\ngpgcheck=0" >> /etc/yum.repos.d/cifwk.repo && \
        echo -e "[rhelrepo]\nname=RHEL Repository\nbaseurl=https://cifwk-oss.lmera.ericsson.se/static/staticRepos/RHEL6.6_OS_DVD/latest\nenabled=1\ngpgcheck=0" >> /etc/yum.repos.d/patches.repo && \
        echo -e "[patchesrepo]\nname=RHEL Patches Repository\nbaseurl=https://cifwk-oss.lmera.ericsson.se/static/staticRepos/RHEL6.6_OS_Patch_Set_CXP9026826-1.30.2\nenabled=1\ngpgcheck=0" >> /etc/yum.repos.d/patches.repo && \
        yum -y update && \
        echo -e "[extra]\nname=extra\nbaseurl=https://cifwk-oss.lmera.ericsson.se/static/dynamicRepos/atvts818yumRepo\nenabled=1\ngpgcheck=0" >> /etc/yum.repos.d/extra.repo && \
        yum install -y ERIClitpvmmonitord_CXP9031644 && \
        yum install -y EXTRlitprsyslogelasticsearch_CXP9032173 && \
        rm -f /etc/yum.repos.d/extra.repo && \
        yum install -y tar && \
        yum install -y EXTRserverjre_CXP9035480 && \
        yum clean all
ENV JAVA_HOME=/usr/java/latest
ENV PATH=$PATH:$JAVA_HOME/bin
ENV PATH=$PATH:/sbin
ENV PATH=$PATH:/usr/sbin
COPY image_content/rsyslog.d/* /etc/rsyslog.d/
COPY image_content/limits.d/* /etc/security/limits.d/
RUN sed -i '$ i\*               -       nofile          10240' /etc/security/limits.conf && \
        sed -i '$ i\*               -       nproc           10240' /etc/security/limits.conf && \
        sed -i 's/1024/10240/g' /etc/security/limits.d/90-nproc.conf && \
        mkdir /var/log/sso && \
        service rsyslog stop && \
        service vmmonitord stop
