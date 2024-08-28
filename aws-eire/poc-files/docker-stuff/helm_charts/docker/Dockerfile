FROM registry.access.redhat.com/rhel6/rhel

MAINTAINER delads

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
	rm -f /etc/yum.repos.d/extra.repo && \
        yum install -y tar vim && \
        yum install -y EXTRserverjre_CXP9035480 && \
        yum clean all

ENV JAVA_HOME=/usr/java/latest
ENV PATH=$PATH:$JAVA_HOME/bin
ENV PATH=$PATH:/sbin
ENV PATH=$PATH:/usr/sbin
COPY helm /usr/local/bin/helm
COPY create_helmcharts.sh /root/
RUN chmod 755 /root/create_helmcharts.sh
RUN chmod 755 /usr/local/bin/helm
RUN mkdir -p /root/.helm/starters/stateless/
COPY stateless /root/.helm/starters/stateless/
COPY stateful /root/.helm/starters/stateful/
