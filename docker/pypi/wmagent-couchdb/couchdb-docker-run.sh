#!/bin/bash

### This script is to be used for running the Couchdb docker container at a VM
### Its sole purpose is to set all the needed mount points from the Host VM and
### forward all Couchdb runtime parameters to the Couchdb container entrypoint run.sh
### It accepts only the set of parameters relevant to Couchdb's container run.sh
### and no build dependent ones. The docker image tag to be searched for execution is
### always `latest`.


# NOTE: In the help call to the current script we only repeat the help and usage
#       information for all the parameters accepted by run.sh.
help(){
    echo -e $*
    cat <<EOF

The script to be used for running a Couchdb docker container at a VM. The full set of arguments
passed to the current script are to be forwarded to the Couchdb container entrypoint 'run.sh'

Usage: couchdb-docker-run.sh [-t <couchdb_tag>] [-p] [-h]

    -p                Pull the image from registry.cern.ch
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
COUCH_TAG=3.2.2


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

# This is the root at the host only, it may differ from the root inside the container.
# NOTE: this may be parameterized, so that the container can run on a different mount point.
HOST_MOUNT_DIR=/data/dockerMount

thisUser=$(id -un)
thisGroup=$(id -gn)

# create the passwd and group mount point dynamically at runtime
passwdEntry=$(getent passwd $thisUser | awk -F : -v thisHome="/home/$thisUser" '{print $1 ":" $2 ":" $3 ":" $4 ":" $5 ":" thisHome ":" $7}')
groupEntry=$(getent group $thisGroup)

# workaround case where Unix account is not in the local system (e.g. sssd)
[[ -d $HOST_MOUNT_DIR/admin/etc/ ]] || (mkdir -p $HOST_MOUNT_DIR/admin/etc) || exit $?
[[ -f $HOST_MOUNT_DIR/admin/etc/passwd ]] || {
    echo "Creating passwd file"
    getent passwd > $HOST_MOUNT_DIR/admin/etc/passwd
    echo $passwdEntry >> $HOST_MOUNT_DIR/admin/etc/passwd
}
[[ -f $HOST_MOUNT_DIR/admin/etc/group ]] || {
    echo "Creating group file"
    getent group > $HOST_MOUNT_DIR/admin/etc/group
    echo $groupEntry >> $HOST_MOUNT_DIR/admin/etc/group
}

[[ -d $HOST_MOUNT_DIR/certs ]] || mkdir -p $HOST_MOUNT_DIR/certs || exit $?
[[ -d $HOST_MOUNT_DIR/admin/couchdb ]] || mkdir -p $HOST_MOUNT_DIR/admin/couchdb || exit $?
[[ -d $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/config  ]] || mkdir -p $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/config  || exit $?
[[ -d $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/install ]] || mkdir -p $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/install || exit $?
[[ -d $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/logs ]] || mkdir -p $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/logs || exit $?
[[ -d $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/state ]] || mkdir -p $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/state || exit $?


dockerOpts="
--detach \
--network=host \
--rm \
--hostname=$(hostname -f) \
--user $(id -u):$(id -g) \
--name=couchdb \
--mount type=bind,source=/tmp,target=/tmp \
--mount type=bind,source=$HOST_MOUNT_DIR/certs,target=/data/certs \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/install,target=/data/srv/couchdb/current/install \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/logs,target=/data/srv/couchdb/current/logs \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/state,target=/data/srv/couchdb/current/state \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/config,target=/data/srv/couchdb/current/config \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/wmagent,target=/data/admin/wmagent/ \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/couchdb,target=/data/admin/couchdb/ \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/etc/passwd,target=/etc/passwd,readonly \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/etc/group,target=/etc/group,readonly \
--mount type=bind,source=/etc/sudoers,target=/etc/sudoers,readonly \
--mount type=bind,source=/etc/sudoers.d,target=/etc/sudoers.d,readonly \
"

# --mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/config,target=/data/srv/couchdb/current/config \
# --mount type=bind,source=$HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG/install/database,target=/data/srv/couchdb/current/install/database \

registry=local
repository=wmagent-couchdb

$PULL && {
    registry=registry.cern.ch
    project=cmsweb
    echo "Pulling Docker image: $registry/$project/$repository:$COUCH_TAG"
    docker pull $registry/$project/$repository:$COUCH_TAG
    docker tag  $registry/$project/$repository:$COUCH_TAG $registry/$repository:$COUCH_TAG
    docker tag  $registry/$project/$repository:$COUCH_TAG $registry/$repository:latest
}

echo "Starting couchdb:$COUCH_TAG docker container with user: $thisUser:$thisGroup"
docker run $dockerOpts $registry/$repository:$COUCH_TAG && (
    [[ -h $HOST_MOUNT_DIR/srv/couchdb/current ]] && rm -f $HOST_MOUNT_DIR/srv/couchdb/current
    ln -s $HOST_MOUNT_DIR/srv/couchdb/$COUCH_TAG $HOST_MOUNT_DIR/srv/couchdb/current )
