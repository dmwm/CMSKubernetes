#!/bin/bash
echo "Creating necessary directories on the host to persist logs and data"
mkdir -p /data/srv/logs/couchdb/
mkdir -p /data/srv/state/couchdb/database/
mkdir -p /data/srv/state/couchdb/stagingarea/
sudo chown _couchdb /data/srv/logs/couchdb/
sudo chown -R _couchdb /data/srv/state/couchdb

# TODO FIXME: this section needs to be fixed with a new destination directory
secr_dir=/data/user/amaltaro/
# export the NODE variable before running it
echo "Copying couch credentials from node: $NODE to $secr_dir"
scp $USER@$NODE:/data/srv/current/auth/couchdb/couch_creds $secr_dir
echo "Copying couch standard local.ini from node: $NODE to $secr_dir"
scp $USER@$NODE:/data/srv/current/config/couchdb/local.ini $secr_dir

# Define command line arguments for docker run
dockerOpts=" \
--detach \
--network=host \
--rm \
--hostname=$(hostname -f) \
--name=couchdb \
--mount type=bind,source=$secr_dir,target=/etc/secrets \
--mount type=bind,source=/data/srv/state/couchdb/database,target=/data/srv/state/couchdb/database \
--mount type=bind,source=/data/srv/state/couchdb/stagingarea,target=/data/srv/state/couchdb/stagingarea \
--mount type=bind,source=/data/srv/logs/couchdb,target=/data/srv/logs/couchdb \
"

couch_tag=3.2.2-alan1
echo "Executing docker run for CouchDB tag: $couch_tag"
docker run $dockerOpts registry.cern.ch/cmsweb/couchdb:$couch_tag && docker logs -f couchdb