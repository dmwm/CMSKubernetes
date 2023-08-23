#!/bin/bash

### This script is to be used for running the Couchdb docker container at a VM
### Its sole purpose is to set all the needed mount points from the Host VM and
### forward all Couchdb runtime parameters to the Couchdb container entrypoint run.sh
### It accepts only the set of parameters relevant to Couchdb's container run.sh
### and no build dependent ones. The docker image tag to be searched for execution is
### always `latest`.


# NOTE: In the help call to the current scrit we only repeat the help and usage
#       information for all the parameters accepted by run.sh.
help(){
    echo -e $*
    cat <<EOF

The script to be used for running a Couchdb docker container at a VM. The full set of arguments
passed to the current script are to be forwarded to the Couchdb container entrypoint 'run.sh'

Usage: couchdb-docker-run.sh [-t <team_name>] [-n <agent_number>] [-f <db_flavour>]

    -p <pull_image>   Pull the image from registry.cern.ch
    -t <couchdb_tag>  The Couchdb version/tag to be downloaded from registry.cern.ch [Default:latest]
    -h <help>

Example: ./couchdb-docker-run.sh -t 3.2.2

EOF
}

usage(){
    help $*
    exit 1
}

PULL=false
COUCH_TAG=3.3.2


### Argument parsing:
while getopts ":t:hp" opt; do
    case ${opt} in
        t) COUCH_TAG=$OPTARG ;;
        p) PULL=true ;;
        h) help; exit $? ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done


couchdbUser=couchdb
couchOpts=" --user $couchdbUser"

# This is the root at the host only, it may differ from the root inside the container.
# NOTE: this may be parametriesed, so that the container can run on a different mount point.
HOST_MOUNT_DIR=/data/dockerMount

[[ -d $HOST_MOUNT_DIR/certs ]] || (mkdir -p $HOST_MOUNT_DIR/certs) || exit $?
[[ -d $HOST_MOUNT_DIR/admin/couchdb ]] || (mkdir -p $HOST_MOUNT_DIR/admin/couchdb) || exit $?
[[ -d $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/config  ]] || (mkdir -p $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/config)  || exit $?
[[ -d $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/install/database ]] || { sudo mkdir -p $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/install/database ;} || exit $?
[[ -d $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/logs ]] || { sudo mkdir -p $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/logs ;} || exit $?

sudo chown -R $couchdbUser:$couchdbUser $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG


dockerOpts="
--detach \
--network=host \
--rm \
--hostname=`hostname -f` \
--name=couchdb \
--mount type=bind,source=/tmp,target=/tmp \
--mount type=bind,source=$HOST_MOUNT_DIR/certs,target=/data/certs \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/install/database,target=/data/srv/couchdb/current/install/database \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/config,target=/data/srv/couchdb/current/config \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/logs,target=/data/srv/couchdb/current/logs \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/wmagent,target=/data/admin/wmagent/ \
"



# couchOpts=$*
# couchOpts="$couchOpts --user couchdb -e COUCHDB_USER=TestAdmin -e COUCHDB_PASSWORD=TestPass"

$PULL && {
    echo "Pulling Docker image: registry.cern.ch/cmsweb/couchdb:$COUCH_TAG"
    docker login registry.cern.ch
    docker pull registry.cern.ch/cmsweb/couchdb:$COUCH_TAG
    docker tag registry.cern.ch/cmsweb/couchdb:$COUCH_TAG local/couchdb:$COUCH_TAG
    docker tag registry.cern.ch/cmsweb/couchdb:$COUCH_TAG local/couchdb:latest
}

echo "Starting the couchdb:$COUCH_TAG docker container with the following parameters: $couchOpts"
docker run $dockerOpts $couchOpts local/couchdb:$COUCH_TAG && (
    [[ -h $HOST_MOUNT_DIR/srv/couchdb/currrent ]] && sudo rm -f $HOST_MOUNT_DIR/srv/couchdb/currrent
    sudo ln -s $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG $HOST_MOUNT_DIR/srv/couchdb/currrent )
