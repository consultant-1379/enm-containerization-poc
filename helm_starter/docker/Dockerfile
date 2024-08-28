FROM armdocker.rnd.ericsson.se/proj_oss_releases/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

COPY helm /usr/local/bin/helm
COPY create_charts.sh /root/
RUN chmod 755 /root/create_charts.sh
RUN chmod 755 /usr/local/bin/helm
RUN mkdir -p /root/.helm/starters/
COPY enm /root/.helm/starters/enm/