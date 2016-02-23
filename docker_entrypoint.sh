#!/bin/bash

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
for i in /opt/tomcat/conf/context.xml;
do
  sed -i -e "s/%MYSQL_HOST%/$MYSQL_HOST/" $i
  sed -i -e "s/%MYSQL_PORT%/$MYSQL_PORT/" $i
  sed -i -e "s/%MYSQL_USERNAME%/$MYSQL_USERNAME/" $i
  sed -i -e "s/%MYSQL_PASSWORD%/$MYSQL_PASSWORD/" $i
  sed -i -e "s/%MYSQL_DATABASE%/$MYSQL_DATABASE/" $i
done

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

  rm /opt/tomcat/conf/tomcat-users.xml
  echo "Tomcat Manager disabled"

fi


# if [[ -e /etc/apache2/conf.d/ssl.conf.bak ]]; then
#   cp /etc/apache2/conf.d/ssl.conf.bak /etc/apache2/conf.d/ssl.conf
# else
#   cp /etc/apache2/conf.d/ssl.conf /etc/apache2/conf.d/ssl.conf.bak
# fi

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

#export SSL_CERT=we_done_switched_the_ssl_cert
if [[ -n "$SSL_CERT" ]]; then
  sed -i 's#SSLCertificateFile=".*#SSLCertificateFile="'$SSL_CERT'"#g' /opt/tomcat/conf/server.xml
fi
#grep "we_done_switched_the_ssl_cert" /etc/apache2/conf.d/ssl.conf

# export SSL_KEY=we_done_switched_the_ssl_key
if [[ -n "$SSL_KEY" ]]; then
  sed -i 's#SSLCertificateKeyFile=".*#SSLCertificateKeyFile="'$SSL_KEY'"#g' /opt/tomcat/conf/server.xml
fi
# grep "we_done_switched_the_ssl_key" /etc/apache2/conf.d/ssl.conf

# # export SSL_CA_CHAIN=we_done_switched_the_cert_chain
# if [[ -n "$SSL_CA_CHAIN" ]]; then
#   sed -i 's#\#SSLCertificateChainFile=".*#SSLCertificateChainFile="'$SSL_CA_CHAIN'"#g' /opt/tomcat/conf/server.xml
# fi
# grep "we_done_switched_the_cert_chain" /etc/apache2/conf.d/ssl.conf

# export SSL_CA_CERT=we_done_switched_the_ca_cert
if [[ -n "$SSL_CA_CERT" ]]; then
  sed -i 's#SSLCACertificatePath=".*#SSLCACertificatePath="'$SSL_CA_CERT'"#g' /opt/tomcat/conf/server.xml
fi
# grep "we_done_switched_the_ca_cert" /etc/apache2/conf.d/ssl.conf

# create the scratch directory
if [[ -z "$IPLANT_SERVER_TEMP_DIR" ]]; then
	IPLANT_SERVER_TEMP_DIR=/scratch
fi

mkdir -p "$IPLANT_SERVER_TEMP_DIR"

# start ntpd because clock skew is astoundingly real
ntpd -d -p pool.ntp.org

# unpack the zip ourselves. This saves about a minute on startup time
WAR_NAME=$(ls $CATALINA_HOME/webapps/*.war 2> /dev/null)
if [[ -n "$WAR_NAME" ]]; then
	APP_NAME=$(basename $WAR_NAME | cut -d'.' -f1)
	echo "expanding war ${WAR_NAME}..."
	mkdir "$CATALINA_HOME/webapps/$APP_NAME"
	unzip -q -o -d "$CATALINA_HOME/webapps/$APP_NAME" "$WAR_NAME"
	rm -f ${WAR_NAME}
else
	echo "No war found in webapps directory."
fi

# Enable NewRelic if a valid key was passed in. We move this to the bottom so
# we can default to the service manifest if no app name was provided.
if [[ -n "$NEWRELIC_LICENSE_KEY" ]]; then
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

fi

# finally, run the command passed into the container
exec "$@"
