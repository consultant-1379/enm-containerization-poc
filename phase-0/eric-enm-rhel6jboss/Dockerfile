FROM 152254703525.dkr.ecr.eu-west-1.amazonaws.com/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads
COPY image_content/EXTRnativecomponents_CXP9031617-1.2.9.rpm /var/tmp/
RUN yum install -y EXTRjboss_CXP9031339 /var/tmp/EXTRnativecomponents_CXP9031617-1.2.9.rpm nc vim rsync && \
        yum clean all && \
        rm -f /var/tmp/EXTRnativecomponents_CXP9031617-1.2.9.rpm
