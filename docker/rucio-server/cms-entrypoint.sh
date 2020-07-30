#! /bin/bash

mkdir -p /opt/rucio/etc/mail_templates/
cp  /root/mail_templates/* /opt/rucio/etc/mail_templates/
ls /opt/rucio/etc/mail_templates/

/usr/sbin/fetch-crl & 

/usr/sbin/crond 

mkdir -p /var/log/rucio/
chown -R apache /var/log/rucio/

/docker-entrypoint.sh

