## Agave Java API Base Image

This is the base image used to create the Agave Java API Images. It has Tomcat 6 and Oracle JDK7 installed and configured with a JNDI connection to a linked MySQL server at host `mysql` and port `3306`.

## What is the Agave Platform?

The Agave Platform ([http://agaveapi.co](http://agaveapi.co)) is an open source, science-as-a-service API platform for powering your digital lab. Agave allows you to bring together your public, private, and shared high performance computing (HPC), high throughput computing (HTC), Cloud, and Big Data resources under a single, web-friendly REST API.

* Run scientific codes

  *your own or community provided codes*

* ...on HPC, HTC, or cloud resources

  *your own, shared, or commercial systems*

* ...and manage your data

  *reliable, multi-protocol, async data movement*

* ...from the web

  *webhooks, rest, json, cors, OAuth2*

* ...and remember how you did it

  *deep provenance, history, and reproducibility built in*

For more information, visit the [Agave Developer’s Portal](http://agaveapi.co) at [http://agaveapi.co](http://agaveapi.co).


## Using this image

This image can be used as a base image for all Java APIs. Simply create a Dockerfile that inherits this base image and add your war file to the Tomcat webapps folder /usr/local/tomcat/webapps.

Tomcat has a preconfigured JNDI connection with the following configuration:

  <Resource name="jdbc/iplant_io"
        auth="Container"
        type="javax.sql.DataSource"
        factory="org.apache.tomcat.dbcp.dbcp.BasicDataSourceFactory"
        removeAbandoned="true"
        removeAbandonedTimeout="30"
        validationQuery="SELECT 1"
        loginTimeout="10"
        maxActive="30"
        maxIdle="5"
        maxWait="5000"
        timeBetweenEvictionRunsMillis="60000"
        poolPreparedStatements="true"
        username="agaveuser"
        password="password"
        driverClassName="com.mysql.jdbc.Driver"
        url="jdbc:mysql://mysql:3306/agave-api?zeroDateTimeBehavior=convertToNull&amp;sessionVariables=FOREIGN_KEY_CHECKS=0&amp;relaxAutoCommit=true"
        useUnicode="true"
        characterEncoding="utf-8"
        characterSetResults="utf8"/>

The mysql driver is already present in the image.


### Running this image

This image extends the trusted php:5.4-apache image.

    > docker run -d -h agave.example.com         	  \
               -p 8888:8080                   		  \ # Tomcat
               --name apache-php
               -v `pwd`/logs:/usr/local/tomcat/logs \ # mount the log directory
               agaveapi/java-api-base
