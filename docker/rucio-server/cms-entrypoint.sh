#! /bin/bash

/usr/sbin/fetch-crl & 

/usr/sbin/crond 

mkdir -p /var/log/rucio/
chown -R apache /var/log/rucio/

/docker-entrypoint.sh
