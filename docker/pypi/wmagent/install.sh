#!/bin/bash

### This script is used to create a WMAgent Docker image and is based
### on deploy-wmagent.sh.
###
### It downloads a CMSWEB deployment tag and then uses the Deploy script
### with the arguments provided in the command line to create the image
###
### It simply deploys the agent based on WMAgent version tag. Patches can be
### applied when the agent container is started. Configuration changes are made
### when the container is started with run.sh.
###
### Have a single parameter, taken as a first argument at runtime - The WMA_TAG
###

set -x

WMA_TAG=$1
WMA_TAG_REG="^[0-9]+\.[0-9]+\.[0-9]{1,2}(\.[0-9]{1,2})?$"
[[ $WMA_TAG =~ $WMA_TAG_REG ]] || { echo "WMA_TAG: $WMA_TAG does not match requered expression: $WMA_TAG_REG"; echo "EXIT with Error 1"  ; exit 1 ;}

BASE_DIR=`pwd`/srv
DEPLOY_DIR=$BASE_DIR/wmagent/$WMA_TAG
CURRENT_DIR=$BASE_DIR/wmagent/current
MANAGE_DIR=$BASE_DIR/wmagent/current/config/wmagent/
ADMIN_DIR=$BASE_DIR/admin/wmagent
ENV_FILE=$BASE_DIR/admin/wmagent/env.sh
CERTS_DIR=$BASE_DIR/certs/

# Set up required directories
mkdir -p $ADMIN_DIR $CERTS_DIR
chmod 755 $CERTS_DIR

echo "Starting new agent deployment with the following data:"
echo " - WMAgent version : $WMA_TAG"
echo

mkdir -p $DEPLOY_DIR || true
ln -s $DEPLOY_DIR $CURRENT_DIR

cd $BASE_DIR

# Download the environment file
wget -nv https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/env.sh -O $ENV_FILE

if [[ -f $ENV_FILE ]]; then
  source $ENV_FILE
else
  echo -e "\n  Could not find $ENV_FILE, exiting."
  exit 1
fi

# Installing the wmagent package from pypi:
echo "Start installing wmagent:$WMA_TAG at $DEPLOY_DIR"
pip install wmagent==$WMA_TAG -t $DEPLOY_DIR || { err=$?; echo "Failed to install wmagent:$WMA_TAG at $DEPLOY_DIR" ; exit $err ; }
echo "Done!" && echo

# ### Enabling couch watchdog; couchdb fix for file descriptors
# echo "*** Enabling couch watchdog ***"
# sed -i "s+RESPAWN_TIMEOUT=0+RESPAWN_TIMEOUT=5+" $CURRENT_DIR/sw*/$WMA_ARCH/external/couchdb*/*/bin/couchdb
# sed -i "s+exec 1>&-+exec 1>$CURRENT_DIR/install/couchdb/logs/stdout.log+" $CURRENT_DIR/sw*/$WMA_ARCH/external/couchdb*/*/bin/couchdb
# sed -i "s+exec 2>&-+exec 2>$CURRENT_DIR/install/couchdb/logs/stderr.log+" $CURRENT_DIR/sw*/$WMA_ARCH/external/couchdb*/*/bin/couchdb
# echo "Done!" && echo

###
# set scripts and specific cronjobs
###
echo "*** Downloading utilitarian scripts ***"
cd $ADMIN_DIR
wget -nv https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/checkProxy.py -O checkProxy.py
wget -nv https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/restartComponent.sh -O restartComponent.sh
wget -nv https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/renew_proxy.sh -O renew_proxy.sh
chmod +x renew_proxy.sh restartComponent.sh
echo "Done!" && echo

# # remove the "install" subdirs, these will be mounted from the host
# echo "*** Removing install subdirs ***"
# rmdir -v /data/srv/wmagent/current/install/*

# remove the "config" subdirs, these will be mounted from the host
echo "*** Removing config subdirs ***"
rm -rfv /data/srv/wmagent/current/config/*

echo "Docker build finished!!" && echo
echo "Have a nice day!" && echo

exit 0
