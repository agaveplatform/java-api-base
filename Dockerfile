######################################################
#
# Agave Java 7 Tomcat 6 Base Image
# Tag: agaveapi/java-api-base
#
# This is the base image for Agave's Java APIs. It
# contains Java 7, Tomcat 7, and configs to access
# a linked mysql jndi connection at hostname `mysql`
# on port 3306.
#
# You can also
# use the following commands to start up Agave and its
# dependencies manually.
#
# Start data volume
# docker run --name mydata agaveapi/api-data-volume echo "Data volume for my APIs"
#
# Start mysql
# docker run --name mysql -d            \ # Run detached in background
#						 --volumes-from mydata      \ # Persist to data volume
#            -v /var/lib/mysql 					\ # Persistent just the db directory
#						 agaveapi/mysql-dev
#
# Start MongoDB:
# docker run --name mongo -d       \ # Run detached in background
#						 --volumes-from mydata \ # Persist to data volume
#            -v /data/db 	         \ # Persistent db directory
#						 agaveapi/mongo-dev
#
# Start beanstalkd:
# docker run --name beanstalkd -d          \ # Run detached in background
#						 --volumes-from mydata         \ # Persist to data volume
#						 -v /var/lib/beanstalkd/binlog \ # Persistent db directory
#						 agaveapi/beanstalkd
#
# Start PHP
# docker run --name my-php-api -d         \ # Run detached in background
#            -e "SERVICE_NAME=my-php-api" \ # Pass in service name for logging
#            -p 80:80                     \ # HTTP
#            --link mysql:mysql           \ # MySQL server
#            --link mongo:mongo						\ # MongoDB server
#            --link beanstalkd:beanstalkd \ # Beanstalkd server
#            --volumes-from mydata        \ # Persistent data volume
#            -v /agave/logs/my-php-api:/var/log/supervisor \ # Persistent log dir
#            agaveapi/java-api-base
#
# https://bitbucket.org/taccaci/agave-docker-java-api-base
#
######################################################

FROM tomcat:6-jre7
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu>

ENV DEBIAN_FRONTEND noninteractive
RUN mkdir -p /usr/local/tomcat/.globus && \
    mkdir -p /scratch && \
    mkdir -p /usr/local/tomcat/logs && \
    cp /usr/share/zoneinfo/America/Chicago /etc/localtime

# Install Tomcat config files for JNDI and better file upload/throughput
ADD tomcat /usr/local/tomcat/
ADD docker_entrypoint.sh /docker_entrypoint.sh

ENV X509_CERT_DIR /usr/local/tomcat/.globus
ENV CATALINA_OPTS "-Djsse.enableCBCProtection=false"

VOLUME [ "/usr/local/tomcat/.globus" ]
VOLUME [ "/scratch" ]
VOLUME [ "/usr/local/tomcat/logs" ]

EXPOSE 8080 8443

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["catalina.sh", "run", "2>&1"]
