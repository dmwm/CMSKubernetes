#!/bin/bash
##H Usage: build.sh <pkgs>
##H
##H Available actions:
##H   help       show this help
##H   pkgs       quoted list of packages to build
##H

# build.sh: script to build docker images for cmsweb services
# for each data service we can adjust which host to use via
# CMSK8S_PROD, CMSK8S_PREP, CMSK8S_DEV, CMSK8S_PRIV environments
# which defiles a hostname to use for cmsweb production, preproduction,
# development and private instance on k8s cluster

# define help
usage="Usage: build.sh <pkgs>"
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
    echo $usage
    exit 1
fi

# adjust if necessary
CMSK8S=${CMSK8S:-https://cmsweb-test.web.cern.ch}
CMSK8STAG=${CMSK8STAG:-}

echo "to prune all images"
echo "docker system prune -f -a"

cmssw_pkgs="cmsweb proxy frontend exporters das dbs2go dbs couchdb reqmgr2 reqmgr2ms reqmon workqueue acdcserver alertscollector confdb crabserver crabcache cmsmon dmwmmon dqmgui t0_reqmon t0wmadatasvc dbsmigration phedex sitedb httpgo httpsgo tfaas"

if [ $# -eq 1 ]; then
    cmssw_pkgs="$1"
fi
echo "Build: $cmssw_pkgs"
echo "CMSK8S=$CMSK8S"
echo "CMSK8STAG=$CMSK8STAG"

exit 1

repo=cmssw
for pkg in $cmssw_pkgs; do
    echo "### build $repo/$pkg"
    docker build --build-arg CMSK8S=$CMSK8S -t $repo/$pkg $pkg
    echo "### existing images"
    docker images
    docker push $repo/$pkg
    if [ -n $CMSK8STAG ]; then
        docker push $repo/$pkg:$CMSK8STAG
    fi
    if [ "$pkg" != "cmsweb" ]; then
        docker rmi $repo/$pkg
    fi
done

echo
echo "To remove all images please use this command"
echo "docker rmi \$(docker images -qf \"dangling=true\")"
echo "docker images | awk '{print \"docker rmi -f \"$3\"\"}' | /bin/sh"
