#!/bin/bash
### This script relies on provided configuration files which will be
### be mounted to /etc/secrets area

# start cron daemon
echo "Docker container has been started"

# Setup a cron schedule
echo "0 * * * * /data/CMSKubernetes/kubernetes/cmsweb/scripts/quota.sh /etc/secrets/env.sh >> /var/log/cron.log 2>&1" > scheduler.txt

crontab scheduler.txt
sudo /usr/sbin/crond -n
