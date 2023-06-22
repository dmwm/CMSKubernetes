#!/bin/bash

### This script is to be used for running the WMAgent docker container at a VM
### Its sole purpose is to set all the needed mount points from the Host VM and
### forward all WMAgent runtime parameters to the WMAgent container entrypoint run.sh
### It accepts only the set of parameters relevant to WMAgent's container run.sh
### and no build dependent ones. The docker image tag to be searched for execution is
### always `latest`.


# NOTE: In the help call to the current scrit we only repeat the help and usage
#       information for all the parameters accepted by run.sh.
help(){
    echo -e $*
    cat <<EOF

The script to be used for running a WMAgent docker container at a VM. The full set of arguments
passed to the current script are to be forwarded to the WMAgent container entrypoint 'run.sh'

Usage: wmagent-docker-run.sh [-t <team_name>] [-n <agent_number>] [-f <db_flavour>]

    -p <pull_image>   Pull the image from registry.cern.ch
    -v <wmagent_tag>  The WMAgent version/tag to be downloaded from registry.cern.ch [Default:latest]

    -t <team_name>    Team name in which the agent should be connected to
    -n <agent_number> Agent number to be set when more than 1 agent connected to the same team (Default: 0)
    -f <db_flavour>   Relational Database flavour. Possible optinos are: 'mysql' or 'oracle' (Default: myslq)

Example: ./wmagent-docker-run.sh -n 30 -t testbed-vocms001 -c cmsweb-testbed.cern.ch -f mysql

EOF
}

usage(){
    help $*
    exit 1
}

PULL=false
WMA_TAG=latest

### Argument parsing:
while getopts ":v:hp" opt; do
    case ${opt} in
        v) WMA_TAG=$OPTARG ;;
        p) PULL=true ;;
        h) help; exit $? ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done

# This is the root at the host only, it may differ from the root inside the container.
# NOTE: this may be parametriesed, so that the container can run on a different mount point.
WMA_ROOT_DIR=/data/dockerMount

[[ -d $WMA_ROOT_DIR/certs ]] || (mkdir -p $WMA_ROOT_DIR/certs) || exit $?
[[ -d $WMA_ROOT_DIR/admin/wmagent ]] || (mkdir -p $WMA_ROOT_DIR/admin/wmagent) || exit $?
[[ -d $WMA_ROOT_DIR/srv/wmagent/current/install ]] || (mkdir -p $WMA_ROOT_DIR/srv/wmagent/current/install) || exit $?
[[ -d $WMA_ROOT_DIR/srv/wmagent/current/config  ]] || (mkdir -p $WMA_ROOT_DIR/srv/wmagent/current/config)  || exit $?

# NOTE: Before mounting /etc/tnsnames.ora we should check it exists, otherwise the run will fail on the FNAL agents
tnsMount=""
[[ -f /etc/tnsnames.ora ]] && tnsMount="--mount type=bind,source=/etc/tnsnames.ora,target=/etc/tnsnames.ora,readonly "

dockerOpts=" \
--network=host \
--rm \
--hostname=`hostname -f` \
--name=wmagent \
$tnsMount
--mount type=bind,source=/etc/condor,target=/etc/condor,readonly \
--mount type=bind,source=/tmp,target=/tmp \
--mount type=bind,source=$WMA_ROOT_DIR/certs,target=/data/certs \
--mount type=bind,source=$WMA_ROOT_DIR/srv/wmagent/current/install,target=/data/srv/wmagent/current/install \
--mount type=bind,source=$WMA_ROOT_DIR/srv/wmagent/current/config,target=/data/srv/wmagent/current/config \
--mount type=bind,source=$WMA_ROOT_DIR/admin/wmagent,target=/data/admin/wmagent/hostadmin \
"

wmaOpts=$*

$PULL && {
    echo "Pulling Docker image: registry.cern.ch/cmsweb/wmagent:$WMA_TAG"
    docker login registry.cern.ch
    docker pull registry.cern.ch/cmsweb/wmagent:$WMA_TAG
    docker tag registry.cern.ch/cmsweb/wmagent:$WMA_TAG wmagent:$WMA_TAG
    docker tag registry.cern.ch/cmsweb/wmagent:$WMA_TAG wmagent:latest
}

# docker run $dockerOpts wmagent:$WMA_TAG $wmaOpts
echo "Starting the wmagent:$WMA_TAG docker container with the following parameters: $wmaOpts"
docker run $dockerOpts wmagent:$WMA_TAG $wmaOpts
