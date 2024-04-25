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

Usage: mariadb-docker-run.sh [-t <mariadb_tag>] [-p]

    -t <mariadb_tag>  The Mariadb version/tag to be downloaded from registry.cern.ch [Default:latest]
    -p                Pull the image from registry.cern.ch
    -h                Help

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

# This is the root at the host only, it may differ from the root inside the container.
# NOTE: this may be parametriesed, so that the container can run on a different mount point.
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

[[ -d $HOST_MOUNT_DIR/certs ]] || (mkdir -p $HOST_MOUNT_DIR/certs) || exit $?
[[ -d $HOST_MOUNT_DIR/admin/mariadb ]] || (mkdir -p $HOST_MOUNT_DIR/admin/mariadb) || exit $?
# [[ -d $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/config  ]] || (mkdir -p $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/config)  || exit $?
[[ -d $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/install/database ]] || { mkdir -p $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/install/database ;} || exit $?
[[ -d $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/logs ]] || { mkdir -p $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/logs ;} || exit $?


dockerOpts="
--detach \
--network=host \
--rm \
--hostname=$(hostname -f) \
--user $(id -u):$(id -g) \
--name=mariadb \
--mount type=bind,source=/tmp,target=/tmp \
--mount type=bind,source=$HOST_MOUNT_DIR/certs,target=/data/certs \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/install/database,target=/data/srv/mariadb/current/install/database \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/logs,target=/data/srv/mariadb/current/logs \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/mariadb,target=/data/admin/mariadb/ \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/wmagent,target=/data/admin/wmagent/ \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/etc/passwd,target=/etc/passwd,readonly \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/etc/group,target=/etc/group,readonly \
--mount type=bind,source=/etc/sudoers,target=/etc/sudoers,readonly \
--mount type=bind,source=/etc/sudoers.d,target=/etc/sudoers.d,readonly \
"

# --mount type=bind,source=$HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG/config,target=/data/srv/mariadb/current/config \

registry=local
repository=mariadb

$PULL && {
    registry=registry.cern.ch
    project=cmsweb
    repository=mariadb
    echo "Pulling Docker image: registry.cern.ch/cmsweb/mariadb:$MDB_TAG"
    docker pull $registry/$project/$repository:$MDB_TAG
    docker tag  $registry/$project/$repository:$MDB_TAG $registry/$repository:$MDB_TAG
    docker tag  $registry/$project/$repository:$MDB_TAG $registry/$repository:latest
}

echo "Starting $repository:$MDB_TAG docker container with user: $thisUser:$thisGroup"
docker run $dockerOpts $registry/$repository:$MDB_TAG && (
    [[ -h $HOST_MOUNT_DIR/srv/mariadb/current ]] && rm -f $HOST_MOUNT_DIR/srv/mariadb/current
    ln -s $HOST_MOUNT_DIR/srv/mariadb/$MDB_TAG $HOST_MOUNT_DIR/srv/mariadb/current )
