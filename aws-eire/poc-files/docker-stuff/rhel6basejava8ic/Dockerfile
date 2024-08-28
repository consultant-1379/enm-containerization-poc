FROM 152254703525.dkr.ecr.eu-west-1.amazonaws.com/eirepoc1-registry:rhel6basejava8

RUN yum -y downgrade glibc glibc-common elfutils-libelf nss-softokn nss-softokn-freebl file-libs policycoreutils audit-libs libsemanage audit-libs

RUN rm -f /etc/yum.repos.d/*

COPY enm.repo /etc/yum.repos.d/
COPY rhel6.repo /etc/yum.repos.d/
COPY rhel6_updates.repo /etc/yum.repos.d/
COPY check_service.sh /var/tmp/

EXPOSE 12987 80 443 8666 22 123 
