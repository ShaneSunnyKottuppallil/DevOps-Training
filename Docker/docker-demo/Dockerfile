FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ARG MYSQLDB=fundoodb
ARG MYSQLUSER=fundoo
ARG MYSQLPASSWORD=fundoo123

ENV DBNAME=${MYSQLDB} \
    DBUSER=${MYSQLUSER} \
    DBPASS=${MYSQLPASSWORD}


RUN apt-get update && apt-get install -y  mysql-server

RUN mkdir -p /mysql \
    chown mysql:mysql /mysql


COPY --chmod=755 entrypoint.sh /
RUN chmod +x entrypoint.sh
COPY mysqlconfig.sql /mysqlconfig.sql

RUN chown mysql:mysql mysqlconfig.sql

RUN mysqld --initialize-insecure --user=mysql --datadir=/mysql


EXPOSE 3306
ENTRYPOINT ["/entrypoint.sh"]
