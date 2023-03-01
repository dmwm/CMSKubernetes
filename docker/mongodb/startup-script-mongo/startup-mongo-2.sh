#!/bin/bash

mkdir -p /data/db/rs-2
# /root/initialize-users.sh &
export POD_IP_ADDRESS=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
mongod --replSet $RS_NAME --port 27017 --bind_ip localhost,$POD_IP_ADDRESS --dbpath /data/db/rs-2 --oplogSize 128 --keyFile /etc/secrets/mongokeyfile
