#!/bin/bash

### This script is to be used for running the WMAgent docker container at a VM
### Its sole purpose is to set all the needed mount points from the Host VM. Create
### all proper links at the host pointing to the currently executing container's tag and
### run the docekr cointainer. The Default docker image tag to be searched for execution is
### `latest`.

help(){
    echo -e $*
    cat <<EOF

The script to be used for running a WMAgent docker container at a VM.

Usage: wmagent-docker-run.sh [-t <wmagent_tag] [-p]

    -t <wmagent_tag>  The WMAgent version/tag to be downloaded from registry.cern.ch [Default:latest]
    -p <pull_image>   Bool flag to pull the image from registry.cern.ch [Default:False]


Example: ./wmagent-docker-run.sh -t 2.2.3.2 -p

EOF
}

usage(){
    help $*
    exit 1
}

PULL=false
WMA_TAG=latest

### Argument parsing:
while getopts ":t:hp" opt; do
    case ${opt} in
        t) WMA_TAG=$OPTARG ;;
        p) PULL=true ;;
        h) help; exit $? ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done

# Parsing the WMA_TAG in parts step by step
WMA_VER_MINOR=${WMA_TAG#*.*.}
WMA_VER_MAJOR=${WMA_TAG%.$WMA_VER_MINOR}
WMA_VER_MINOR=${WMA_VER_MINOR%rc*}
WMA_VER_MINOR=${WMA_VER_MINOR%.*}
WMA_VER_RELEASE=${WMA_VER_MAJOR}.${WMA_VER_MINOR}
WMA_VER_PATCH=${WMA_TAG#$WMA_VER_RELEASE}
WMA_VER_PATCH=${WMA_VER_PATCH#.}
echo -e "Using WMAgent version: $WMA_TAG under release: $WMA_VER_RELEASE\n"

wmaUser=$(id -un)
wmaGroup=$(id -gn)

# This is the root at the host only, it may differ from the root inside the container.
# NOTE: This is parametriesed, so that the container can run on a different mount point.
#       A soft link is needed to mimic the same /data tree as inside the container so
#       that condor may find the job cache and working directories:
HOST_MOUNT_DIR=/data/dockerMount
[[ -h /data/srv/wmagent ]] && rm -f /data/srv/wmagent
ln -s $HOST_MOUNT_DIR/srv/wmagent /data/srv/wmagent

# create the passwd and group mount point dynamically at runtime
passwdEntry=$(getent passwd $wmaUser | awk -F : -v wmaHome="/home/$wmaUser" '{print $1 ":" $2 ":" $3 ":" $4 ":" $5 ":" wmaHome ":" $7}')
groupEntry=$(getent group $wmaGroup)

# workaround case where Unix account is not in the local system (e.g. sssd)
[[ -d $HOST_MOUNT_DIR/admin/etc/ ]] || (mkdir -p $HOST_MOUNT_DIR/admin/etc) || exit $?
if ! [ -f $HOST_MOUNT_DIR/admin/etc/passwd ]; then
    echo "Creating passwd file"
    getent passwd > $HOST_MOUNT_DIR/admin/etc/passwd
    echo $passwdEntry >> $HOST_MOUNT_DIR/admin/etc/passwd
fi
if ! [ -f $HOST_MOUNT_DIR/admin/etc/group ]; then
    echo "Creating group file"
    getent group > $HOST_MOUNT_DIR/admin/etc/group
    echo $groupEntry >> $HOST_MOUNT_DIR/admin/etc/group
fi

# create regular mount points at runtime
[[ -d $HOST_MOUNT_DIR/admin/wmagent ]] || (mkdir -p $HOST_MOUNT_DIR/admin/wmagent) || exit $?
[[ -d $HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/install ]] || (mkdir -p $HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/install) || exit $?
[[ -d $HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/config  ]] || (mkdir -p $HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/config)  || exit $?
[[ -d $HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/logs ]] || { mkdir -p $HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/logs ;} || exit $?

# NOTE: Before mounting /etc/tnsnames.ora we should check it exists, otherwise the run will fail on the FNAL agents
tnsMount=""
[[ -f /etc/tnsnames.ora ]] && tnsMount="--mount type=bind,source=/etc/tnsnames.ora,target=/etc/tnsnames.ora,readonly "

dockerOpts=" \
--detach \
--network=host \
--rm \
--hostname=$(hostname -f) \
--user $(id -u):$(id -g) \
--name=wmagent \
$tnsMount \
--mount type=bind,source=/etc/condor,target=/etc/condor,readonly \
--mount type=bind,source=/tmp,target=/tmp \
--mount type=bind,source=/data/certs,target=/data/certs \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/install,target=/data/srv/wmagent/current/install \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/config,target=/data/srv/wmagent/current/config \
--mount type=bind,source=$HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE/logs,target=/data/srv/wmagent/current/logs \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/wmagent,target=/data/admin/wmagent \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/etc/passwd,target=/etc/passwd,readonly \
--mount type=bind,source=$HOST_MOUNT_DIR/admin/etc/group,target=/etc/group,readonly \
--mount type=bind,source=/etc/sudoers,target=/etc/sudoers,readonly \
--mount type=bind,source=/etc/sudoers.d,target=/etc/sudoers.d,readonly \
--mount type=bind,source=/etc/vomses,target=/etc/vomses \
"

registry=local
repository=wmagent
$PULL && {
    registry=registry.cern.ch
    project=cmsweb
    repository=wmagent
    echo "Pulling Docker image: registry.cern.ch/cmsweb/wmagent:$WMA_TAG"
    docker login registry.cern.ch
    docker pull $registry/$project/$repository:$WMA_TAG
    docker tag $registry/$project/$repository:$WMA_TAG $registry/$repository:$WMA_TAG
    docker tag $registry/$project/$repository:$WMA_TAG $registry/$repository:latest
}

echo "Checking if there is no other wmagent container running and creating a link to the $WMA_VER_RELEASE in the host mount area."
[[ $(docker container inspect -f '{{.State.Status}}' wmagent 2>/dev/null) == 'running' ]] || (
    [[ -h $HOST_MOUNT_DIR/srv/wmagent/current ]] && rm -f $HOST_MOUNT_DIR/srv/wmagent/current
    ln -s $HOST_MOUNT_DIR/srv/wmagent/$WMA_VER_RELEASE $HOST_MOUNT_DIR/srv/wmagent/current )

echo "Starting wmagent:$WMA_TAG docker container with user: $wmaUser:$wmaGroup"
docker run $dockerOpts $registry/$repository:$WMA_TAG
docker exec -u root -it wmagent service cron start
