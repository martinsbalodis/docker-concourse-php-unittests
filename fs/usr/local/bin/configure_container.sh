#!/usr/bin/env bash

echo "starting supervisor"
/usr/bin/supervisord -c/etc/supervisor/supervisord.conf &

# wait for services to start
sleep 10

echo "doing some setup"
mysql -uroot -p$DB_PASSWORD -e "create database $DB_DATABASE CHARACTER SET utf8 COLLATE utf8_general_ci"