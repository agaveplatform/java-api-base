######################################################
#
# Agave Java 7 Tomcat 8 Base Image
# Tag: agaveapi/java-api-base
#
# This is the base image for Agave's Java APIs. It
# contains Java 7, Tomcat 8, implicit CORS support,
# and configs to autowire a MySQL or MariaDB
# server from the environment.
#
# https://bitbucket.org/agaveapi/java-api-base
# http://agaveapi.co
#
######################################################

FROM jeanblanchard/tomcat:tomcat8-java7
MAINTAINER Rion Dooley <dooley@tacc.utexas.edu>

ADD tcp/limits.conf /etc/security/limits.conf
ADD tcp/sysctl.conf /etc/sysctl.conf

RUN addgroup -g 50 -S tomcat && \
    adduser -u 1000 -g tomcat -G tomcat -S tomcat  && \
    apk --update add bash tzdata apr bash openssl apr-dev openssl-dev build-base && \
    cd /opt/tomcat/bin && \
    tar xzf tomcat-native.tar.gz && \
    rm tomcat-native.tar.gz && \
    cd $CATALINA_HOME/bin/tomcat-native-1.1.33-src/jni/native/ && \
    ./configure --with-apr=/usr/bin/apr-1-config --with-java-home=$JAVA_HOME  --with-ssl=yes --prefix=/usr && \
    make && \
    make install && \
    cd / && \
    curl -O http://www.us.apache.org/dist//ant/binaries/apache-ant-1.9.6-bin.tar.gz && \
    tar xzf apache-ant-1.9.6-bin.tar.gz && \
    cd $CATALINA_HOME/bin/tomcat-native-*-src/jni && \
    /apache-ant-1.9.6/bin/ant download && \
    /apache-ant-1.9.6/bin/ant && \
    /apache-ant-1.9.6/bin/ant jar && \
    cp dist/tomcat-native-*.jar $CATALINA_HOME/lib/ && \
    echo "Setting up ntpd..." && \
    echo $(setup-ntp -c busybox  2>&1) && \
    echo "Setting system timezone to America/Chicago..." && \
    ln -snf /usr/share/zoneinfo/America/Chicago /etc/localtime && \
    mkdir -p /opt/tomcat/.globus && \
    mkdir -p /scratch && \
    mkdir -p /opt/tomcat/logs && \
    rm -rf /opt/tomcat/bin/tomcat-native-*-src && \
    apk del apr-dev openssl-dev build-base && rm -f /var/cache/apk/* && \
    rm -rf /apache-ant-1.9.6* && \
    ln -s /lib/libuuid.so.1 /usr/lib/libuuid.so.1
    #apk --update add libuuid && rm -f /var/cache/apk/*
    # && \
    # ln -s /usr/lib/libuuid.so /usr/lib/libuuid.so.1

    #sysctl -p && \
		#apk install curl unzip - && \
    #cd /opt/tomcat/
    #curl "http://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic-java.zip" && \
		#unzip newrelic-jar.zip && \
		#rm /tmp/newrelic-jar.zip && \
		#cd newrelic && \
		#java -jar newrelic.jar install

# Delete the ROOT, manager, and host-manager app
RUN rm -rf /opt/tomcat/webapps/manager /opt/tomcat/webapps/host-manager /opt/tomcat/webapps/ROOT /opt/tomcat/webapps/*.war && \
    mkdir /opt/tomcat/webapps/ROOT


# Install Tomcat config files for JNDI and better file upload/throughput
ADD tomcat/conf/* /opt/tomcat/conf/
ADD tomcat/lib/*.jar /opt/tomcat/lib/
#ADD newrelic.yml /newrelic/newrelic.yml
ADD docker_entrypoint.sh /docker_entrypoint.sh

ENV X509_CERT_DIR /opt/tomcat/.globus
ENV CATALINA_OPTS "-Duser.timezone=America/Chicago -Djsse.enableCBCProtection=false -Djava.awt.headless=true -Dfile.encoding=UTF-8 -server -Xms1024m -Xmx4096m -XX:NewSize=256m -XX:MaxNewSize=256m -XX:PermSize=256m -XX:MaxPermSize=512m -XX:+DisableExplicitGC -Djava.security.egd=file:/dev/./urandom"
ENV PATH $PATH:/opt/tomcat/bin

WORKDIR /opt/tomcat

VOLUME [ "/opt/tomcat/.globus" ]
VOLUME [ "/scratch" ]
VOLUME [ "/opt/tomcat/logs" ]

EXPOSE 80 443 8009

ENTRYPOINT ["/docker_entrypoint.sh"]

CMD ["/opt/tomcat/bin/catalina.sh", "run", "2>&1"]
