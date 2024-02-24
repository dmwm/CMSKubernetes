#!/bin/bash

### This script is to be used for running the Mariadb docker container at a VM
### Its sole purpose is to set all the needed mount points from the Host VM and
### forward all Mariadb runtime parameters to the Mariadb container entrypoint run.sh
### It accepts only the set of parameters relevant to Mariadb's container run.sh
### and no build dependent ones. The docker image tag to be searched for execution is
### always `latest`.


# NOTE: In the help call to the current scrit we only repeat the help and usage
#       information for all the parameters accepted by run.sh.
help(){
    echo -e $*
    cat <<EOF

The script to be used for running a Mariadb docker container at a VM. The full set of arguments
passed to the current script are to be forwarded to the Mariadb container entrypoint 'run.sh'

Usage: mariadb-docker-run.sh [-t <team_name>] [-n <agent_number>] [-f <db_flavour>]

    -p <pull_image>   Pull the image from registry.cern.ch
    -t <mariadb_tag>  The Mariadb version/tag to be downloaded from registry.cern.ch [Default:latest]
    -h <help>

Example: ./mariadb-docker-run.sh -t 3.2.2

EOF
}

usage(){
    help $*
    exit 1
}

PULL=false
MDB_TAG=latest


### Argument parsing:
while getopts ":t:hp" opt; do
    case ${opt} in
        t) MDB_TAG=$OPTARG ;;
        p) PULL=true ;;
        h) help; exit $? ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done


mariadbUser=cmst1
mariadbOpts=" --user $mariadbUser"

# This is the root at the host only, it may differ from the root inside the container.
# NOTE: this may be parametriesed, so that the container can run on a different mount point.
HOST_MOUNT_DIR=/data/dockerMount

[[ -d $HOST_MOUNT_DIR/certs ]] || (mkdir -p $HOST_MOUNT_DIR/certs) || exit $?
[[ -d $HOST_MOUNT_DIR/admin/mariadb ]] || (mkdir -p $HOST_MOUNT_DIR/admin/mariadb) || exit $?
# [[ -d $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/config  ]] || (mkdir -p $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/config)  || exit $?
[[ -d $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/install/database ]] || { mkdir -p $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/install/database ;} || exit $?
[[ -d $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/logs ]] || { mkdir -p $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/logs ;} || exit $?

# sudo chown -R $mariadbUser:$mariadbUser $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG

dockerOpts="
--detach \
--network=host \
--rm \
--hostname=`hostname -f` \
--name=mariadb \
--mount type=bind,source=/tmp,target=/tmp \
--mount type=bind,source=$HOST_MOUNT_DIR/certs,target=/data/certs \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/install/database,target=/data/srv/mariadb/current/install/database \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/logs,target=/data/srv/mariadb/current/logs \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/mariadb,target=/data/admin/mariadb/ \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/wmagent,target=/data/admin/wmagent/ \
"

# --mount type=bind,source=$HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/config,target=/data/srv/mariadb/current/config \

# mariadbOpts=$*
# mariadbOpts="$mariadbOpts --user mariadb -e MARIADB_USER=TestAdmin -e MARIADB_PASSWORD=TestPass"

$PULL && {
    echo "Pulling Docker image: registry.cern.ch/cmsweb/mariadb:$MDB_TAG"
    docker login registry.cern.ch
    docker pull registry.cern.ch/cmsweb/mariadb:$MDB_TAG
    docker tag registry.cern.ch/cmsweb/mariadb:$MDB_TAG local/mariadb:$MDB_TAG
    docker tag registry.cern.ch/cmsweb/mariadb:$MDB_TAG local/mariadb:latest
}

echo "Starting the mariadb:$MDB_TAG docker container with the following parameters: $mariadbOpts"
docker run $dockerOpts $mariadbOpts local/mariadb:$MDB_TAG && (
    [[ -h $HOST_MOUNT_DIR/srv/mariadb/current ]] && rm -f $HOST_MOUNT_DIR/srv/mariadb/current
    ln -s $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG $HOST_MOUNT_DIR/srv/mariadb/current )
