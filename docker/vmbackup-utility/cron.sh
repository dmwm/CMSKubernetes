#!/bin/bash

echo "*/5 * * * * /data/run.sh" >> /tmp/mycron
crontab /tmp/mycron
rm /tmp/mycron
