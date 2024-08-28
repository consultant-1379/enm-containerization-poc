FROM k8s-registry.eccd.local/rhel6base:green
MAINTAINER dudderlads
RUN groupadd -g 205 jboss && \
        useradd -gjboss -u 308 -d /home/jboss_user jboss_user && \
        yum install -y EXTRjboss_CXP9031339.noarch EXTRnativecomponents_CXP9031617 nc vim rsync
