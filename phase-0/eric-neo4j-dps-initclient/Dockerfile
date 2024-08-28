FROM openjdk:8u151-jre-alpine3.7
RUN apk add --no-cache unzip bash bind bind-tools
RUN apk add --no-cache jq
COPY image_content/cypher-shell.zip /var/tmp/cypher-shell.zip
RUN  unzip /var/tmp/cypher-shell.zip
RUN  rm -f /var/tmp/cypher-shell.zip
RUN  mkdir /pre-config-custom-scripts && mkdir /post-config-custom-scripts && mkdir /config && mkdir /indexes
COPY image_content/neo4j-user.json /config/
COPY image_content/neo4jIndexes /indexes/
COPY image_content/create_user.sh create_user.sh
COPY image_content/configure.sh configure.sh
COPY image_content/check_neo4j.sh /var/tmp/check_neo4j.sh
