#!/bin/bash

mkdir -p /data/db/rs-0
export POD_IP_ADDRESS=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
/root/reconfig-mongo-rs.sh &
mongod --replSet $RS_NAME --port 27017 --bind_ip localhost,$POD_IP_ADDRESS --dbpath /data/db/rs-0 --oplogSize 128 --keyFile /etc/secrets/mongokeyfile
