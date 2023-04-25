#!/bin/bash

### This script is used to create a WMAgent Docker image and is based on deploy-wmagent.sh
### It simply deploys the agent based on WMAgent version tag provided at runtime.
### * Patches can be applied when the agent container is started.
### * Configuration changes are made when the container is started with `run.sh`.
###
### It takes a single parameter as first (and only) argument at runtime - The WMA_TAG
### Example: install.sh 2.2.0.2

pythonLib=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

WMA_TAG=$1
WMA_TAG_REG="^[0-9]+\.[0-9]+\.[0-9]{1,2}(\.[0-9]{1,2})?$"
[[ $WMA_TAG =~ $WMA_TAG_REG ]] || { echo "WMA_TAG: $WMA_TAG does not match requered expression: $WMA_TAG_REG"; echo "EXIT with Error 1"  ; exit 1 ;}

echo
echo "======================================================="
echo "Starting new agent deployment with the following data:"
echo "-------------------------------------------------------"
echo " - WMAgent version         : $WMA_TAG"
echo " - Python verson           : $(python --version)"
echo " - Python Module Path      : $pythonLib"
echo "======================================================="
echo

set -x

# Set up required directories
mkdir -p $DEPLOY_DIR || true
ln -s $DEPLOY_DIR $CURRENT_DIR

mkdir -p $ADMIN_DIR $CERTS_DIR $MANAGE_DIR $INSTALL_DIR
chmod 755 $CERTS_DIR

cd $BASE_DIR

# Download the environment file
wget -nv https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/env.sh -O $ENV_FILE

if [[ -f $ENV_FILE ]]; then
  source $ENV_FILE
else
  echo -e "\n  Could not find $ENV_FILE, exiting."
  exit 1
fi

# Installing the wmagent package from pypi
# First upgrade pip to the latest version:
echo "Upgrading pip to the latest vestion:"
pip install wheel
pip install --upgrade pip
echo

echo "Start installing wmagent:$WMA_TAG at $DEPLOY_DIR"
# pip install wmagent==$WMA_TAG --prefix=$DEPLOY_DIR || { err=$?; echo "Failed to install wmagent:$WMA_TAG at $DEPLOY_DIR" ; exit $err ; }
pip install wmagent==$WMA_TAG || { err=$?; echo "Failed to install wmagent:$WMA_TAG at $DEPLOY_DIR" ; exit $err ; }
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

# # remove the "config" subdirs, these will be mounted from the host
# echo "*** Removing config subdirs ***"
# rm -rfv /data/srv/wmagent/current/config/*

echo "Docker build finished!!" && echo
echo "Have a nice day!" && echo

exit 0
