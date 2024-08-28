FROM 152254703525.dkr.ecr.eu-west-1.amazonaws.com/enm/eric-enm-rhel6base:latest
MAINTAINER dudderlads

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils openldap sqlite db4 db4-utils audit-libs libsemanage audit-libs ncurses ncurses-base ncurses-libs iptables.x86_64 && \
    mkdir -p /ericsson/tor/data && \
    mkdir -p /etc/opt/ericsson/ERICmodeldeployment && \
    mkdir -p /ericsson/batch && \
    mkdir -p /ericsson/config_mgt && \
    mkdir -p /ericsson/enm/dumps && \
    mkdir -p /root/.ssh && \
    touch /root/.ssh/id_rsa && \
    chmod 700 /root/.ssh

COPY image_content/check_service_availability.sh image_content/rename_currentxml.sh image_content/setup-neo4j-subsystem.sh image_content/cmserv_config.sh image_content/register_web_context.sh /var/tmp/
COPY image_content/postgres_key.pem  /root/.ssh/id_rsa
RUN  chmod 600 /root/.ssh/id_rsa

EXPOSE 12987 8080 9990 4447 9999 1636 7999 4320 8085 8445
EXPOSE 3000-64000
