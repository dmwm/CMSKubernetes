#!/bin/bash
COUCH_LOGS_DIR=/data/srv/logs/couchdb/
COUCH_DB_DIR=/data/srv/state/couchdb/database/
COUCH_STAGING_DIR=/data/srv/state/couchdb/stagingarea/
COUCH_USR=_couchdb

echo "Creating necessary directories on the host to persist logs and data"
mkdir -p $COUCH_LOGS_DIR
mkdir -p $COUCH_DB_DIR
mkdir -p $COUCH_STAGING_DIR
sudo chown $COUCH_USR $COUCH_LOGS_DIR
sudo chown -R $COUCH_USR $COUCH_DB_DIR/..

# Define directory to store credentials and standard configuration
COUCH_SECR_DIR=/data/srv/auth/couchdb/
echo "Creating directory to store credentials and local.ini under: $COUCH_SECR_DIR"
mkdir -p $COUCH_SECR_DIR

# export the NODE variable before running it
echo "Copying couch credentials from node: $NODE to $COUCH_SECR_DIR"
scp $USER@$NODE:/data/srv/current/auth/couchdb/couch_creds $COUCH_SECR_DIR
echo "Copying couch standard local.ini from node: $NODE to $COUCH_SECR_DIR"
scp $USER@$NODE:/data/srv/current/config/couchdb/local.ini $COUCH_SECR_DIR
sudo chown -R $COUCH_USR:zh $COUCH_SECR_DIR

# Define command line arguments for docker run
dockerOpts=" \
--detach \
--network=host \
--hostname=$(hostname -f) \
--name=couchdb \
--mount type=bind,source=$COUCH_SECR_DIR,target=/etc/secrets \
--mount type=bind,source=$COUCH_DB_DIR,target=$COUCH_DB_DIR \
--mount type=bind,source=$COUCH_STAGING_DIR,target=$COUCH_STAGING_DIR \
--mount type=bind,source=$COUCH_LOGS_DIR,target=$COUCH_LOGS_DIR \
"

couch_tag=3.2.2-v6
echo "Executing docker run for CouchDB tag: $couch_tag"
docker run $dockerOpts registry.cern.ch/cmsweb/couchdb:$couch_tag && docker logs -f couchdb