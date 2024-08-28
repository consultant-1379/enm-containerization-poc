FROM openjdk:8u151-jre-alpine3.7
RUN apk add --no-cache unzip bash bind bind-tools 
RUN apk add --no-cache jq
COPY cypher-shell.zip /var/tmp/cypher-shell.zip 
RUN  unzip /var/tmp/cypher-shell.zip 
RUN  rm -f /var/tmp/cypher-shell.zip
RUN  mkdir /pre-config-custom-scripts && mkdir /post-config-custom-scripts
COPY create_user.sh create_user.sh
COPY configure.sh configure.sh
