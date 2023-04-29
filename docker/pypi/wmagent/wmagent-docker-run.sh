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
    echo -e $1
    cat <<EOF

The script to be used for running a WMAgent docker container at a VM. The full set of arguments
passed to the current script are to be forwarded to the WMAgent container entrypoint 'run.sh'

Usage: wmagent-docker-run.sh [-t <team_name>] [-n <agent_number>] [-c <central_services_url>] [-f <db_flavour>]

    -t <team_name>    Team name in which the agent should be connected to
    -n <agent_number> Agent number to be set when more than 1 agent connected to the same team (Default: 0)
    -f <db_flavour>   Relational Database flavour. Possible optinos are: 'mysql' or 'oracle' (Default: myslq)
    -c <central_services> Url to central services hosting central couchdb (Default: cmsweb-testbed.cern.ch)

Example: ./wmagent-docker-run.sh -w 2.2.0.2 -n 30 -t testbed-vocms001 -c cmsweb-testbed.cern.ch

EOF
}

usage(){
    help $1
    exit 1
}

### Argument parsing:
while getopts ":h" opt; do
    case ${opt} in
        h) help; exit $? ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done

# WMA_TAG=latest
dockerOpts=" \
--network=host \
--rm \
--hostname=`hostname -f` \
--name=wmagent \
-v /data/certs:/data/certs:Z,ro \
-v /etc/condor:/etc/condor:Z,ro \
-v /tmp:/tmp:Z \
-v /data/srv/wmagent/current/install:/data/srv/wmagent/current/install:Z \
-v /data/srv/wmagent/current/config:/data/srv/wmagent/current/config:Z \
-v /data/admin/wmagent:/data/admin/wmagent/hostadmin:Z \
"
wmaOpts=$*

# docker run $dockerOpts wmagent:$WMA_TAG $wmaOpts
docker run $dockerOpts wmagent $wmaOpts
