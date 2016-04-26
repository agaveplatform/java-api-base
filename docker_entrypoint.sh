#!/bin/bash
set +e

genpasswd() {
	local l=$1
       	[ "$l" == "" ] && l=16
      	tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}

if [[ -f "/app/config/environment.sh" ]]; then
  source /app/config/environment.sh
else
  echo "No environment config present in /app/config/environment.sh. Reading from container environment"
fi

#################################################################
# Configure MySQL jndi connection
#################################################################

if [[ -z "$MYSQL_HOST" ]]; then
  MYSQL_HOST=mysql
fi

if [[ -n "$MYSQL_PORT_3306_TCP_PORT" ]]; then
  MYSQL_PORT=3306
elif [[ -z "$MYSQL_PORT" ]]; then
  MYSQL_PORT=3306
fi

if [[ -n "$MYSQL_ENV_MYSQL_USERNAME" ]]; then
  MYSQL_USERNAME=$MYSQL_ENV_MYSQL_USERNAME
elif [[ -z "$MYSQL_USERNAME" ]]; then
  MYSQL_USERNAME=agaveuser
fi

if [[ -n "$MYSQL_ENV_MYSQL_PASSWORD" ]]; then
  MYSQL_PASSWORD=$MYSQL_ENV_MYSQL_PASSWORD
elif [[ -z "$MYSQL_PASSWORD" ]]; then
  MYSQL_PASSWORD=password
fi

if [[ -n "$MYSQL_ENV_MYSQL_DATABASE" ]]; then
  MYSQL_DATABASE=$MYSQL_ENV_MYSQL_DATABASE
elif [[ -z "$MYSQL_DATABASE" ]]; then
  MYSQL_DATABASE=agave-api
fi

# Update database config
echo "Updating container mysql connection to jdbc://mysql/${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}..."
for i in /opt/tomcat/conf/context.xml;
do
  sed -i -e "s/%MYSQL_HOST%/$MYSQL_HOST/" $i
  sed -i -e "s/%MYSQL_PORT%/$MYSQL_PORT/" $i
  sed -i -e "s/%MYSQL_USERNAME%/$MYSQL_USERNAME/" $i
  sed -i -e "s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/" $i
  sed -i -e "s/%MYSQL_DATABASE%/$MYSQL_DATABASE/" $i
done

#################################################################
# Enable/disable Tomcat manager
#################################################################

# Enable Tomcat Manager if a valid key was passed in
if [[ -n "$ENABLE_TOMCAT_MANAGER" ]]; then
  if [[ -z "$TOMCAT_MANGER_USERNAME" ]]; then
    TOMCAT_MANGER_USERNAME=admin
  fi

  if [[ -z "$TOMCAT_MANGER_PASSWORD" ]]; then
    TOMCAT_MANGER_PASSWORD=$(genpasswd)
  fi

  sed -i 's#<user name="admin" password="admin"#<user name="'$TOMCAT_MANGER_USERNAME'" password="'$TOMCAT_MANGER_PASSWORD'"#g' /opt/tomcat/conf/tomcat-users.xsd
  echo "Tomcat Manager admin user: $TOMCAT_MANGER_USERNAME / $TOMCAT_MANGER_PASSWORD"

else
  if [[ -e "/opt/tomcat/conf/tomcat-users.xml" ]]
  then
      rm /opt/tomcat/conf/tomcat-users.xml
      echo "Tomcat Manager disabled"
  fi
fi

#################################################################
# Configure ssl certs to use mounted files or the container defaults
#################################################################

echo "Creating SSL keys for secure communcation..."
if [[ -z "$SSL_KEY" ]]; then
	export KEY=/etc/ssl/private/server.key
	export DOMAIN=$(hostname)
	export PASSPHRASE=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)
	export SUBJ="
C=US
ST=Texas
O=University of Texas
localityName=Austin
commonName=$DOMAIN
organizationalUnitName=TACC
emailAddress=admin@$DOMAIN"
	openssl genrsa -des3 -out /etc/ssl/private/server.key -passout env:PASSPHRASE 2048
	openssl req -new -batch -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key $KEY -out /etc/ssl/certs/$DOMAIN.csr -passin env:PASSPHRASE
	cp $KEY $KEY.orig
	openssl rsa -in $KEY.orig -out $KEY -passin env:PASSPHRASE
	openssl x509 -req -days 365 -in /etc/ssl/certs/$DOMAIN.csr -signkey $KEY -out /etc/ssl/certs/server.crt
fi

if [[ -n "$SSL_CERT" ]]; then
  sed -i 's#SSLCertificateFile=".*#SSLCertificateFile="'$SSL_CERT'"#g' /opt/tomcat/conf/server.xml
fi

if [[ -n "$SSL_KEY" ]]; then
  sed -i 's#SSLCertificateKeyFile=".*#SSLCertificateKeyFile="'$SSL_KEY'"#g' /opt/tomcat/conf/server.xml
fi

# # export SSL_CA_CHAIN=we_done_switched_the_cert_chain
# if [[ -n "$SSL_CA_CHAIN" ]]; then
#   sed -i 's#\#SSLCertificateChainFile=".*#SSLCertificateChainFile="'$SSL_CA_CHAIN'"#g' /opt/tomcat/conf/server.xml
# fi
# grep "we_done_switched_the_cert_chain" /etc/apache2/conf.d/ssl.conf

if [[ -n "$SSL_CA_CERT" ]]; then
  sed -i 's#SSLCACertificatePath=".*#SSLCACertificatePath="'$SSL_CA_CERT'"#g' /opt/tomcat/conf/server.xml
fi

#################################################################
# Scratch directory init
#################################################################

# create the scratch directory
if [[ -z "$IPLANT_SERVER_TEMP_DIR" ]]; then
	IPLANT_SERVER_TEMP_DIR=/scratch
fi

echo "Setting service temp directory to $IPLANT_SERVER_TEMP_DIR..."
mkdir -p "$IPLANT_SERVER_TEMP_DIR"

#################################################################
# NTPD init
#################################################################

# start ntpd because clock skew is astoundingly real
ntpd -d -p pool.ntp.org &

#################################################################
# Unpack webapp
#
# This saves about a minute on startup time
#################################################################

WAR_NAME=$(ls $CATALINA_HOME/webapps/*.war 2> /dev/null)
if [[ -n "$WAR_NAME" ]]; then
	APP_NAME=$(basename $WAR_NAME | cut -d'.' -f1)
	echo "expanding war ${WAR_NAME}..."
	mkdir "$CATALINA_HOME/webapps/$APP_NAME"
	unzip -q -o -d "$CATALINA_HOME/webapps/$APP_NAME" "$WAR_NAME"
	rm -f ${WAR_NAME}
	echo "...done expanding war"
else
	echo "No war found in webapps directory."
fi

#################################################################
# Configure logging
#################################################################

# Configure logging output target. Logs to a file unless explicitly
# configured to send to standard out
if [[ -n "$LOG_TARGET_STDOUT" ]]; then
  LOG_TARGET=stdout
else
	LOG_TARGET=fileout
fi

# Enable toggling the log level at startup. DEBUG for all api services
# by default.
if [[ -n "$LOG_LEVEL_INFO" ]]; then
  LOG_LEVEL=INFO
elif [[ -n "$LOG_LEVEL_ERROR" ]]; then
  LOG_LEVEL=ERROR
elif [[ -n "$LOG_LEVEL_WARN" ]]; then
  LOG_LEVEL=WARN
elif [[ -n "$LOG_LEVEL_NONE" ]]; then
  LOG_LEVEL=NONE
else
	LOG_LEVEL=DEBUG
fi

echo "Setting service log level to $LOG_LEVEL..."
sed -i 's#^agaveLogLevel=.*#agaveLogLevel='$LOG_LEVEL'#g' $CATALINA_HOME/webapps/*/WEB-INF/classes/log4j.properties

echo "Setting service log target to $LOG_TARGET..."
sed -i 's#^logTarget=.*$#logTarget='$LOG_TARGET'#g' $CATALINA_HOME/webapps/*/WEB-INF/classes/log4j.properties

#################################################################
# Configure NewRelic monitor
#
# Enable NewRelic if a valid key was passed in. We move this to the bottom so
# we can default to the service manifest if no app name was provided.
#################################################################

if [[ -n "$NEWRELIC_LICENSE_KEY" ]]; then
	echo "Configuring New Relic support..."
  sed -i -e "s/%NEWRELIC_LICENSE_KEY%/$NEWRELIC_LICENSE_KEY/" $CATALINA_HOME/newrelic/newrelic.yml

	if [[ -z "$AGAVE_APP_NAME" ]]; then
		export $(find $CATALINA_HOME/webapps/*/META-INF/maven -name pom.properties -print0 | xargs grep "artifactId")
		AGAVE_APP_NAME="Agave $(echo $artifactId | sed -e 's#-# #' | awk '{print toupper($0)}')"
  fi
	sed -i -e "s/%AGAVE_APP_NAME%/$AGAVE_APP_NAME/" $CATALINA_HOME/newrelic/newrelic.yml

	if [[ -z "$NEWRELIC_ENVIRONMENT" ]]; then
		if [[ -n "$(echo $HOSTNAME | grep 'prod')" ]]; then
			AGAVE_ENVIRONMENT=Production
		elif [[ -n "$(echo $HOSTNAME | grep 'staging')" ]]; then
			AGAVE_ENVIRONMENT=Staging
		else
			AGAVE_ENVIRONMENT=Development
		fi
	fi
	sed -i -e "s/%AGAVE_ENVIRONMENT%/$AGAVE_ENVIRONMENT/" $CATALINA_HOME/newrelic/newrelic.yml

	export CATALINA_OPTS="$CATALINA_OPTS -javaagent:$CATALINA_HOME/newrelic/newrelic.jar"
	echo "...done configuring NewRelic"
fi

# finally, run the command passed into the container
exec "$@"
