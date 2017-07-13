#!/usr/bin/env bash

docker run -h docker.example.com -p 80:8080 --name some-api -e MYSQL_USERNAME=agaveapi -e MYSQL_PASSWORD=d3f@ult$ -e MYSQL_HOST= 129.114.6.229 -e MYSQL_PORT=3306 agaveapi/java-api-base:8.0.43-java8-hikaricp