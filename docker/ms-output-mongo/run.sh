#!/bin/bash

# start mongo
mkdir -p /data/mongodb/{wtdb,logs}
if [ -f /etc/secrets/mongodb.conf ]; then
    mongod --config /etc/secrets/mongodb.conf
else
    mongod --config /data/mongodb.conf
fi

# mongostat daemon
mongostat --port 8230 --quiet --json 60
