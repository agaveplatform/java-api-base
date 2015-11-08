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

ADD tcp/limits.conf /etc/security/limits.conf
ADD tcp/sysctl.conf /etc/sysctl.conf

RUN mkdir -p /usr/local/tomcat/.globus && \
    mkdir -p /scratch && \
    mkdir -p /usr/local/tomcat/logs && \
    cp /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    mv /usr/local/tomcat/webapps/ROOT /usr/local/tomcat/webapps/TCMgr && \
    rm -rf /webapps/examples && \
		rm -rf /webapps/docs && \
    sysctl -p && \
		apt-get update -y && \
    apt-get install -y vim.tiny wget && \
    wget -q "http://download.newrelic.com/newrelic/java-agent/newrelic-agent/3.15.0/newrelic-java-3.15.0.zip" -O /tmp/newrelic.zip && \
		unzip /tmp/newrelic.zip -d /usr/local/tomcat/ && \
		rm /tmp/newrelic.zip && \
		cd /usr/local/tomcat/newrelic && \
		java -jar newrelic.jar install

# Install Tomcat config files for JNDI and better file upload/throughput
ADD tomcat /usr/local/tomcat/
ADD newrelic.yml /newrelic/newrelic.yml
ADD docker_entrypoint.sh /docker_entrypoint.sh

ENV TERM xterm
ENV X509_CERT_DIR /usr/local/tomcat/.globus
ENV CATALINA_OPTS "-Djsse.enableCBCProtection=false -Djava.awt.headless=true -Dfile.encoding=UTF-8 -server -Xms1024m -Xmx4096m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:PermSize=256m -XX:MaxPermSize=512m -XX:+DisableExplicitGC"

VOLUME [ "/usr/local/tomcat/.globus" ]
VOLUME [ "/scratch" ]
VOLUME [ "/usr/local/tomcat/logs" ]

EXPOSE 8080 8443

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["/usr/local/tomcat/bin/catalina.sh", "run", "2>&1"]
