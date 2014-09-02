#!/bin/bash
MySQLOK=`pidof mysqld > /dev/null; echo $?`
if [ $MySQLOK -eq 1 ]; then
  rm /var/lib/mysql/mysql.sock
  /etc/init.d/mysql51-mysqld start
fi
