FROM 152254703525.dkr.ecr.eu-west-1.amazonaws.com/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads
COPY image_content/check_service.sh /var/tmp/
COPY image_content/cypher-shell.tar /var/tmp/cypher-shell.tar
RUN  tar -xvf /var/tmp/cypher-shell.tar
RUN  rm -f /var/tmp/cypher-shell.tar
