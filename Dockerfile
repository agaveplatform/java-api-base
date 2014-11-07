######################################################
#
# Agave Java 7 Tomcat 7 Base Image
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
# Start MySQL:
# docker run --name some-mysql -d 										\ # Run detached in background
#						 -e MYSQL_ROOT_PASSWORD=mysecretpassword 	\ # Default mysql root user password.
#						 -e MYSQL_DATABASE=agave-api 							\ # Database name. This should be left constant
#						 -e MYSQL_USER=agaveuser 									\ # User username. This can be random as it will be injected at runtime, but should be constant when persisting data
#						 -e MYSQL_PASSWORD=password 							\ # User password. This can be random as it will be injected at runtime, but should be constant when persisting data
#						 -v `pwd`/mysql:/var/lib/mysql 						\ # MySQL data directory for persisting db between container invocations
#						 mysql:5.6
#
# Start MongoDB:
# docker run --name some-mongo -d 		\ # Run detached in background
#						 -v `pwd`/mongo:/data/db 	\ # Mongo data directory for persisting db between invocations
#						 mongo:2.6
#
# Start Beanstalkd:
# docker run --name some-beanstalkd -d -t 				\ # Run detached in background
#            -p 10022:22             							\ # SSHD, SFTP
#            -p 11300:11300												\ # beanstalkd
#            -v `pwd`/beanstalkd:/data 						\ # Beanstalkd data directory for persisting messages between container invocations
#            agaveapi/beanstalkd
#
# Start Tomcat
# docker run -h docker.example.com -i --rm    	  \
#            -p 8080:8080                  			  \ # Tomcat
#            --link some-mysql:mysql              \ # MySQL server
#            --link some-mongo:mongo						  \ # MongoDB server
#            --link some-beanstalkd:beanstalkd    \ # Beanstalkd server
#            --name tomcat											  \ #
#            -v `pwd`/logs:/usr/local/tomcat/logs \ # volume mount log directory
#            agaveapi/java-api-base
#
# https://bitbucket.org/taccaci/agave-docker-java-api-base
#
######################################################

FROM tomcat:6
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu

# Install Tomcat config files for JNDI and better file upload/throughput
ADD tomcat/context.xml /usr/local/tomcat/conf/context.xml
ADD tomcat/server.xml /usr/local/tomcat/conf/server.xml
ADD tomcat/mysql-connector-java-5.1.17-bin.jar /usr/local/tomcat/lib/mysql-connector-java-5.1.17-bin.jar

ENV X509_CERT_DIR /usr/local/tomcat/.globus

USER root

RUN apt-get install -y bind-utils sendmail sendmail-cf

RUN mkdir -p /usr/local/tomcat/.globus && \
    chown -R tomcat /usr/local/tomcat/.globus && \
    mkdir -p /scratch && \
    chown -R tomcat /scratch && \
    mkdir -p /usr/local/tomcat/logs && \
    chown -R tomcat /usr/local/tomcat/logs && \
    chmod 777 /usr/local/tomcat/logs

USER tomcat

VOLUME [ "/usr/local/tomcat/logs" ]
EXPOSE 8080 8443
CMD ["catalina.sh", "run"]
