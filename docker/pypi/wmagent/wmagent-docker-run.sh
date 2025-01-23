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
# This is the root at the host only, it may differ from the root inside the container.
# NOTE: This is parametriesed, so that the container can run on a different mount point.
#       A soft link is needed to mimic the same /data tree as inside the container so
#       that condor may find the job cache and working directories:
HOST_MOUNT_DIR=/data/dockerMount

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
if [[ "$WMA_TAG" == latest ]]; then
    # If it is 'latest', we have to find out what is the actual release version for that
    WMA_VER_RELEASE=$(ls -l $HOST_MOUNT_DIR/srv/wmagent  | grep -v ^l | grep -v total | awk '{print $9}')
fi
echo -e "Using WMAgent version: $WMA_TAG under release: $WMA_VER_RELEASE\n"

wmaUser=$(id -un)
wmaGroup=$(id -gn)

[[ -h /data/srv/wmagent ]] && rm -f /data/srv/wmagent
ln -s $HOST_MOUNT_DIR/srv/wmagent /data/srv/wmagent

# create the passwd and group mount point dynamically at runtime
passwdEntry=$(getent passwd $wmaUser | awk -F : -v wmaHome="/home/$wmaUser" '{print $1 ":" $2 ":" $3 ":" $4 ":" $5 ":" wmaHome ":" $7}')
groupEntry=$(getent group $wmaGroup)

# @TODO: Create needed unix accounts in container, rather than bind mounting files from the host
# workaround case where Unix account is not in the local system (e.g. sssd)
[[ -d $HOST_MOUNT_DIR/admin/etc/ ]] || (mkdir -p $HOST_MOUNT_DIR/admin/etc) || exit $?

# Validation step
# Delete local docker passwd/group files if uucp is not present (so it can be recreated)
[[ -f "$HOST_MOUNT_DIR/admin/etc/passwd" ]] && ! grep -q uucp "$HOST_MOUNT_DIR/admin/etc/passwd" &&  {
        rm $HOST_MOUNT_DIR/admin/etc/passwd
}
[[ -f "$HOST_MOUNT_DIR/admin/etc/group" ]] && ! grep -q uucp "$HOST_MOUNT_DIR/admin/etc/group" &&  {
        rm $HOST_MOUNT_DIR/admin/etc/group
}

if ! [ -f $HOST_MOUNT_DIR/admin/etc/passwd ]; then
    echo "Creating passwd file"
    getent passwd > $HOST_MOUNT_DIR/admin/etc/passwd
    echo $passwdEntry >> $HOST_MOUNT_DIR/admin/etc/passwd
    # add back original system related unix users
    echo "Debian-exim:x:103:105::/var/spool/exim4:/usr/sbin/nologin" >> $HOST_MOUNT_DIR/admin/etc/passwd
    echo "_apt:x:100:65534::/nonexistent:/usr/sbin/nologin" >> $HOST_MOUNT_DIR/admin/etc/passwd
    echo "uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin" >> $HOST_MOUNT_DIR/admin/etc/passwd
fi
if ! [ -f $HOST_MOUNT_DIR/admin/etc/group ]; then
    echo "Creating group file"
    getent group > $HOST_MOUNT_DIR/admin/etc/group
    echo $groupEntry >> $HOST_MOUNT_DIR/admin/etc/group
    # add back original system related groups
    echo "Debian-exim:x:105:" >> $HOST_MOUNT_DIR/admin/etc/group
    echo "messagebus:x:104:" >> $HOST_MOUNT_DIR/admin/etc/group
    echo "crontab:x:103:" >> $HOST_MOUNT_DIR/admin/etc/group
    echo "uucp:x:10:" >> $HOST_MOUNT_DIR/admin/etc/group
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
--mount type=bind,source=/etc/grid-security,target=/etc/grid-security,readonly \
--mount type=bind,source=/etc/vomses,target=/etc/vomses,readonly \
--mount type=bind,source=/etc/s-nail.rc,target=/etc/s-nail_host.rc,readonly \
"

registry=local
repository=wmagent
$PULL && {
    registry=registry.cern.ch
    project=cmsweb
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

echo "Starting $registry/$repository:$WMA_TAG docker container with user: $wmaUser:$wmaGroup"
docker run $dockerOpts $registry/$repository:$WMA_TAG || {
    echo "ERROR: WMAgent already running at this machine. Execution HALTED!"
    exit 1
}
docker exec -u root -it wmagent service cron start

# Workaround su authentication issue (cron uses setuid via su)
# We inherit user accounts from the host (binding files in read-only mode)
# including the password mode (L=locked, P=password)
# If we are in password mode, reset it so we do not get authentication
# errors.
userStatus="$(docker exec -u root -it wmagent sh -c "passwd -S $wmaUser" | awk '{print $2}')"
if [ "${userStatus:0:1}" == "P" ]; then
    docker exec -u root -it wmagent sh -c "echo $wmaUser:$wmaUser | chpasswd"
fi

# Configure s-nail to use the host s-nail mail server
docker exec -u root -it wmagent cp /etc/s-nail_host.rc /etc/s-nail.rc
docker exec -u root -it wmagent sh -c "printf 'set v15-compat\nset smtp-auth=none\nset mta=smtp://127.0.0.1:25' >> /etc/s-nail.rc"
# Change mail to use s-nail
docker exec -u root -it wmagent update-alternatives --install /usr/bin/mailx mailx /usr/bin/s-nail 50 --slave /usr/bin/mail mail /usr/bin/s-nail

