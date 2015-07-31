######################################################
#
# Agave Java 7 Tomcat 6 Base Image
# Tag: agaveapi/java-api-base
#
# This is the base image for Agave's Java APIs. It
# contains Java 7, Tomcat 6, implicit CORS support,
# and configs to autowire a MySQL or MariaDB
# server from the environment.
#
# https://bitbucket.org/taccaci/agave-docker-java-api-base
# http://agaveapi.co
#
######################################################

FROM tomcat:6-jre7
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu>

ENV DEBIAN_FRONTEND noninteractive
RUN mkdir -p /usr/local/tomcat/.globus && \
    mkdir -p /scratch && \
    mkdir -p /usr/local/tomcat/logs && \
    cp /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    mv /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/TCMgr

# Install Tomcat config files for JNDI and better file upload/throughput
ADD tomcat /usr/local/tomcat/
ADD docker_entrypoint.sh /docker_entrypoint.sh

ENV TERM xterm
ENV X509_CERT_DIR /usr/local/tomcat/.globus
ENV CATALINA_OPTS "-Djsse.enableCBCProtection=false"

VOLUME [ "/usr/local/tomcat/.globus" ]
VOLUME [ "/scratch" ]
VOLUME [ "/usr/local/tomcat/logs" ]

EXPOSE 8080 8443

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["/usr/local/tomcat/bin/catalina.sh", "run", "2>&1"]
