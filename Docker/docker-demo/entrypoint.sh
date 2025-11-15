#!/usr/bin/env bash
set -e
exec mysqld --user=mysql --datadir=/mysql --init-file=/mysqlconfig.sql