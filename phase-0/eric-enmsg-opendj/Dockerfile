FROM 152254703525.dkr.ecr.eu-west-1.amazonaws.com/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

RUN mkdir -p /ericsson/tor/data && \
    mkdir -p /ericsson/enm/dumps

COPY image_content/ /var/tmp/

EXPOSE 12987 22 44224 1636 37387 46797 1689 60442 4444 8989 8447 33537
