############
#  postfix
############
chmod +x /opt/postfix.sh
postconf -e myhostname=$HOSTNAME
postconf -F '*/*/chroot = n'

# if the mongo hostname was not found, they didn't link the container the default way
if [[ -n "$(host mongo | grep 'not found')" ]]; then

  # check for the mongo host in the environment
  if [[ -n "$MONGO_HOST" ]]; then

    # check for an ip vs hostname
    if [[ -z "$(host $MONGO_HOST | grep 'not found')" ]]; then

      # can't resolve $MONGO_HOST to a valid ip
      echo "Unable to resolve MongoDB host: $MONGO_HOST"
      die 1

    elif [[ -n "$(host $MONGO_HOST | grep 'has address')" ]]; then

      # $MONGO_HOST resolved to a valid ip
      echo "$(host $MONGO_HOST | awk '{print $4}') mongo" >> /etc/hosts

    else

      # $MONGO_HOST was an ip address
      echo "$MONGO_HOST mongo" >> /etc/hosts

    fi

  else

    # mongo hostname isn't defined in /etc/hosts, the parent /etc/hosts or the
    # environment, so assume it's running on the host server and set to the
    # host ip
    echo "$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')  mongo" >> /etc/hosts

  fi

else

  # Found it already present
  echo "MongoDB server found at $(host mongo | awk '{print $4}')"

fi

# if the mysql hostname was not found, they didn't link the container the default way
if [[ -n "$(host mysql | grep 'not found')" ]]; then

  # check for the mysql host in the environment
  if [[ -n "$MYSQL_HOST" ]]; then

    # check for an ip vs hostname
    if [[ -z "$(host $MYSQL_HOST | grep 'not found')" ]]; then

      # can't resolve $MYSQL_HOST to a valid ip
      echo "Unable to resolve MySQL host: $MYSQL_HOST"
      die 1

    elif [[ -n "$(host $MYSQL_HOST | grep 'has address')" ]]; then

      # $MYSQL_HOST resolved to a valid ip
      echo "$(host $MYSQL_HOST | awk '{print $4}') mysql" >> /etc/hosts

    else

      # $MYSQL_HOST was an ip address
      echo "$MYSQL_HOST mysql" >> /etc/hosts

    fi

  else

    # mysql hostname isn't defined in /etc/hosts, the parent /etc/hosts or the
    # environment, so assume it's running on the host server and set to the
    # host ip
    echo "$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')  mysql" >> /etc/hosts

  fi

else

  # Found it already present
  echo "MySQL server found at $(host mysql | awk '{print $4}')"

fi

# if the beanstalkd hostname was not found, they didn't link the container the default way
if [[ -n "$(host beanstalkd | grep 'not found')" ]]; then

  # check for the beanstalkd host in the environment
  if [[ -n "$BEANSTALKD_HOST" ]]; then

    # check for an ip vs hostname
    if [[ -z "$(host $BEANSTALKD_HOST | grep 'not found')" ]]; then

      # can't resolve $BEANSTALKD_HOST to a valid ip
      echo "Unable to resolve beanstalkd host: $BEANSTALKD_HOST"
      die 1

    elif [[ -n "$(host $BEANSTALKD_HOST | grep 'has address')" ]]; then

      # $BEANSTALKD_HOST resolved to a valid ip
      echo "$(host $BEANSTALKD_HOST | awk '{print $4}') beanstalkd" >> /etc/hosts

    else

      # $BEANSTALKD_HOST was an ip address
      echo "$BEANSTALKD_HOST beanstalkd" >> /etc/hosts

    fi

  else

    # beanstalkd hostname isn't defined in /etc/hosts, the parent /etc/hosts or the
    # environment, so assume it's running on the host server and set to the
    # host ip
    echo "$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')  beanstalkd" >> /etc/hosts

  fi

else

  # Found it already present
  echo "beanstalkd server found at $(host beanstalkd | awk '{print $4}')"

fi

#judgement
if [[ -a /etc/supervisor/conf.d/supervisord.conf ]]; then
  exit 0
fi
