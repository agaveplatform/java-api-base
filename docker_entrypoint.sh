#!/bin/bash

if [[ -f "/app/config/environment.sh" ]]; then
  source /app/config/environment.sh
else
  echo "No environment config present in /app/config/environment.sh. Reading from container environment"
fi
if [[ -z "$MYSQL_HOST" ]]; then
  MYSQL_HOST=mysql
fi

if [[ -n "MYSQL_PORT_3306_TCP_PORT" ]]; then
  MYSQL_PORT=3306
elif [[ -z "$MYSQL_PORT" ]]; then
  MYSQL_PORT=3306
fi

if [[ -z "$MYSQL_ENV_MYSQL_DATABASE" ]]; then
  MYSQL_ENV_MYSQL_DATABASE=agave
fi

if [[ -z "$MYSQL_ENV_MYSQL_PASSWORD" ]]; then
  MYSQL_ENV_MYSQL_PASSWORD=password
fi

if [[ -z "$MYSQL_ENV_MYSQL_DATABASE" ]]; then
  MYSQL_ENV_MYSQL_DATABASE=agave
fi

for i in /usr/local/tomcat/conf/context.xml;
do
  sed -i -e "s/%MYSQL_HOST%/$MYSQL_HOST/" $i
  sed -i -e "s/%MYSQL_PORT%/$MYSQL_PORT/" $i
  sed -i -e "s/%MYSQL_USERNAME%/$MYSQL_ENV_MYSQL_DATABASE/" $i
  sed -i -e "s/%MYSQL_PASSWORD%/$MYSQL_ENV_MYSQL_PASSWORD/" $i
  sed -i -e "s/%MYSQL_DATABASE%/$MYSQL_ENV_MYSQL_DATABASE/" $i
done

#service rsyslog start
exec "$@"
