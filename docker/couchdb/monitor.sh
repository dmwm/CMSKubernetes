#!/bin/bash

# start couchdb exporter
COUCH_CONFIG=/data/srv/current/auth/couchdb/couchdb_config.ini
export COUCHDB_NODE_NAME="couchdb@$(hostname)"
# test if file is not zero size
if [ -s "${COUCH_CONFIG}" ]; then
    sudo cp /etc/secrets/$fname /data/srv/current/auth/$srv/$fname
    sudo chown $USER.$USER /data/srv/current/auth/$srv/$fname
    nohup couchdb-prometheus-exporter -telemetry.address=":9984" -logtostderr=true \
      --config=$COUCH_CONFIG -databases.views=false --databases=_all_dbs 2>&1 1>& couchdb_exporter.log < /dev/null &
else
    echo "ERROR: couchdb_config.ini file is empty and prometheus exporter cannot be started!"
fi

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
