#!/bin/bash
##H Usage: build.sh <pkgs>
##H
##H Available actions:
##H   help       show this help
##H   pkgs       quoted list of packages to build
##H

# build.sh: script to build docker images for cmsweb services
# use CMSK8S environment to control host name of k8s cluster
# use CMSK8STAG environment to specify common tag for build images
# use CMSK8SREPO environment to specify docker hub repo, default is cmssw

# define help
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
    echo "Usage: build.sh <pkgs>"
    echo "  use CMSK8S environment to control host name of k8s cluster"
    echo "  use CMSK8STAG environment to specify common tag for build images"
    echo "  use CMSK8SREPO environment to specify docker hub repo, default is cmssw"
    echo "Examples:"
    echo "  # build images for all cmsweb services"
    echo "  CMSK8STAG=1.0.4 CMSK8S=https://cmsweb-test.cern.ch ./build.sh"
    echo "  # build images for given set of services"
    echo "  CMSK8STAG=1.0.4 CMSK8S=https://cmsweb-test.cern.ch ./build.sh \"dbs reqmgr2\""
    echo "  # build images for given set of services and deploy them into your personal docker repository"
    echo "  # here vvv is a name of docker repository (default is cmssw)"
    echo "  CMSK8SREPO=vvv CMSK8STAG=1.0.4 CMSK8S=https://cmsweb-test.cern.ch ./build.sh \"dbs reqmgr2\""
    exit 1
fi

# adjust if necessary
CMSK8S=${CMSK8S:-https://cmsweb-test.cern.ch}
CMSK8STAG=${CMSK8STAG:-}
CMSWEB_ENV=${CMSWEB_ENV:-preprod}


echo "to prune all images"
echo "docker system prune -f -a"

#cmssw_pkgs="proxy frontend exporters exitcodes nats-sub das dbs2go dbs couchdb reqmgr2 reqmgr2ms reqmon workqueue acdcserver crabserver crabcache cmsmon dmwmmon dqmgui t0_reqmon t0wmadatasvc dbsmigration phedex httpgo httpsgo"

cmssw_pkgs="cmsweb cmsweb-base frontend dbs dbsmigration reqmgr2 reqmon crabserver crabcache t0_reqmon t0wmadatasvc workqueue reqmgr2ms reqmgr2ms-unmerged"

rucio_pkgs="rucio-consistency rucio-daemons rucio-probes rucio-server rucio-sync rucio-tracer rucio-ui rucio-upgrade"

monitoring_pkgs="cmsmon cmsmon-alerts cmsmon-intelligence cmsweb-monit condor-cpu-eff jobber karma monitor nats-nsc nats-sub rumble sqoop vmbackup-utility udp-server"

if [ $# -eq 1 ]; then
    cmssw_pkgs="$1"
fi
echo "Build: $cmssw_pkgs"
echo "CMSK8S=$CMSK8S"
echo "CMSK8STAG=$CMSK8STAG"
echo "CMSWEB_ENV=$CMSWEB_ENV"

registry=registry.cern.ch/cmsweb

repo=${CMSK8SREPO:-cmssw}
echo "repo=$repo"
for pkg in $cmssw_pkgs; do
    if [[ $rucio_pkgs == *$pkg* ]]; then
       registry=registry.cern.ch/cmsrucio
    fi
    if [[ $monitoring_pkgs == *$pkg* ]]; then
       registry=registry.cern.ch/cmsmonitoring
    fi
    if [ "$pkg" == "cmsweb" ] || [ "$pkg" == "cmsweb-base" ]; then
       registry=registry.cern.ch/cmsweb
    fi



  echo "Registry #### $registry"

    echo "### build $repo/$pkg"
    if [ -n "$CMSK8STAG" ]; then
        docker build --build-arg CMSK8S=$CMSK8S --build-arg CMSWEB_ENV=$CMSWEB_ENV -t $repo/$pkg -t $repo/$pkg:$CMSK8STAG $pkg --no-cache
        docker tag $repo/$pkg:$CMSK8STAG $registry/$pkg:$CMSK8STAG
        if [ "$pkg" == "reqmgr2ms" ] ; then
          docker tag $repo/$pkg:$CMSK8STAG $registry/reqmgr2ms-output:$CMSK8STAG
          docker tag $repo/$pkg:$CMSK8STAG $registry/reqmgr2ms-monitor:$CMSK8STAG
          docker tag $repo/$pkg:$CMSK8STAG $registry/reqmgr2ms-rulecleaner:$CMSK8STAG
          docker tag $repo/$pkg:$CMSK8STAG $registry/reqmgr2ms-transferor:$CMSK8STAG
          docker tag $repo/$pkg:$CMSK8STAG $registry/reqmgr2ms-unmerged:$CMSK8STAG
        fi
        if [ "$pkg" == "workqueue" ] ; then
          docker tag $repo/$pkg:$CMSK8STAG $registry/global-workqueue:$CMSK8STAG
        fi

    else
        docker build --build-arg CMSK8S=$CMSK8S --build-arg CMSWEB_ENV=$CMSWEB_ENV  -t $repo/$pkg $pkg
    fi
        docker tag $repo/$pkg $registry/$pkg

    echo "### existing images"
    docker images
    docker push $repo/$pkg
    docker push $registry/$pkg

    if [ -n "$CMSK8STAG" ]; then
        docker push $repo/$pkg:$CMSK8STAG
        docker push $registry/$pkg:$CMSK8STAG
        if [ "$pkg" == "reqmgr2ms" ] ; then
          docker push $registry/reqmgr2ms-output:$CMSK8STAG
          docker push $registry/reqmgr2ms-monitor:$CMSK8STAG
          docker push $registry/reqmgr2ms-rulecleaner:$CMSK8STAG
          docker push $registry/reqmgr2ms-transferor:$CMSK8STAG
          docker push $registry/reqmgr2ms-unmerged:$CMSK8STAG
        fi
        if [ "$pkg" == "workqueue" ] ; then
          docker push $registry/global-workqueue:$CMSK8STAG
        fi

    fi
    if [ "$pkg" != "cmsweb" ] && [ "$pkg" != "cmsweb-base" ]; then
        echo "Images was uploaded to docker hub, time to clean-up, press CTRL+C to interrupt..."
        sleep 5
        docker rmi $repo/$pkg
        docker rmi $registry/$pkg

    	if [ -n "$CMSK8STAG" ]; then
        	docker rmi $repo/$pkg:$CMSK8STAG
                docker rmi $registry/$pkg:$CMSK8STAG
                if [ "$pkg" == "reqmgr2ms" ] ; then
                  docker rmi $registry/reqmgr2ms-output:$CMSK8STAG
                  docker rmi $registry/reqmgr2ms-monitor:$CMSK8STAG
                  docker rmi $registry/reqmgr2ms-rulecleaner:$CMSK8STAG
                  docker rmi $registry/reqmgr2ms-transferor:$CMSK8STAG
                  docker rmi $registry/reqmgr2ms-unmerged:$CMSK8STAG
                fi
               if [ "$pkg" == "workqueue" ] ; then
                  docker rmi $registry/global-workqueue:$CMSK8STAG
               fi

    	fi
    fi
done

echo
echo "To remove all images please use this command"
echo "docker rmi \$(docker images -qf \"dangling=true\")"
echo "docker images | awk '{print \"docker rmi -f \"$3\"\"}' | /bin/sh"
