#!/bin/bash

### This script is used to create a WMAgent Docker image and is based on deploy-wmagent.sh
### It simply deploys the agent based on the WMAgent version/tag provided at runtime.
### * Patches can be applied when the agent container is started.
### * Configuration changes are made when the container is started with `run.sh`.
###
### It takes a single parameter as first (and only) argument at runtime - The WMA_TAG
### Example: install.sh 2.2.0.2

pythonLib=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

help(){
    echo -e $1
    cat <<EOF

The basic WMAgent deployment script for Docker image creation:
Usage: install.sh -v <wmagent_tag>

      -v <wmagent_tag>    The WMAgent version/tag to be used for the Docker image creation

Example: ./install.sh -v 2.2.0.2

EOF
}

usage(){
    help $1
    exit 1
}

WMA_TAG=None

### Argument parsing:
while getopts ":v:" opt; do
    case ${opt} in
        v) WMA_TAG=$OPTARG ;;
        h) help; exit $? ;;
        \? )
            msg="Invalid Option: -$OPTARG"
            usage "$msg" ;;
        : )
            msg="Invalid Option: -$OPTARG requires an argument"
            usage "$msg" ;;
    esac
done

WMA_TAG_REG="^[0-9]+\.[0-9]+\.[0-9]{1,2}(\.[0-9]{1,2})?$"
[[ $WMA_TAG =~ $WMA_TAG_REG ]] || { echo "WMA_TAG: $WMA_TAG does not match requered expression: $WMA_TAG_REG"; echo "EXIT with Error 1"  ; exit 1 ;}

echo
echo "======================================================================="
echo "Starting new WMAgent deployment with the following initialisation data:"
echo "-----------------------------------------------------------------------"
echo " - WMAgent Version            : $WMA_TAG"
echo " - WMAgent User               : $WMA_USER"
echo " - WMAgent Root path          : $WMA_ROOT_DIR"
echo " - Python  Verson             : $(python --version)"
echo " - Python  Module path        : $pythonLib"
echo "======================================================================="
echo


# Installing the wmagent package from pypi
stepMsg="Installing wmagent:$WMA_TAG at $WMA_DEPLOY_DIR"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"

# First upgrade pip to the latest version:
pip install wheel
pip install --upgrade pip

# Second deploy the package. Interrupt on error:
pip install wmagent==$WMA_TAG || { err=$?; echo "Failed to install wmagent:$WMA_TAG at $WMA_DEPLOY_DIR" ; exit $err ; }
echo "Done $stepMsg!" && echo


# Setup required directories
stepMsg="Creating required directory structure in the WMAgent image"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
mkdir -p ${WMA_DEPLOY_DIR} || true
ln -s ${WMA_DEPLOY_DIR%/deploy} $WMA_CURRENT_DIR

mkdir -p $WMA_ADMIN_DIR $WMA_HOSTADMIN_DIR $WMA_CERTS_DIR $WMA_MANAGE_DIR $WMA_INSTALL_DIR
chmod 755 $WMA_CERTS_DIR

cd $WMA_BASE_DIR
echo "Done $stepMsg!" && echo

stepMsg="Downloading all files required for the containder intialisation at the host"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
# Download the environment file
wget -nv -O $WMA_ENV_FILE https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/env.sh

# Download config and manage scripts for the initial deployment:
wget -nv -P $WMA_DEPLOY_DIR https://raw.githubusercontent.com/dmwm/deployment/master/wmagentpy3/manage
wget -nv -P $WMA_DEPLOY_DIR https://raw.githubusercontent.com/dmwm/deployment/master/wmagentpy3/local.ini
wget -nv -P $WMA_DEPLOY_DIR https://raw.githubusercontent.com/dmwm/deployment/master/wmagentpy3/my.cnf
wget -nv -P $WMA_DEPLOY_DIR https://raw.githubusercontent.com/dmwm/deployment/master/wmagentpy3/rucio.cfg

# Download WMAgent.secrets templates:
wget -nv -P $WMA_DEPLOY_DIR https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/WMAgent.production
wget -nv -P $WMA_DEPLOY_DIR https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/WMAgent.testbed

# Download utilitarian scripts:
wget -nv -P $WMA_ADMIN_DIR https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/checkProxy.py
wget -nv -P $WMA_ADMIN_DIR https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/restartComponent.sh
wget -nv -P $WMA_ADMIN_DIR https://raw.githubusercontent.com/dmwm/WMCore/master/deploy/renew_proxy.sh
chmod +x $WMA_ADMIN_DIR/renew_proxy.sh $WMA_ADMIN_DIR/restartComponent.sh
echo "Done $stepMsg!" && echo

###
# Add WMA_USER's runtime aliases:
###

stepMsg="Creating all runtime aliases for the WMA_USER"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
set -x
cat <<EOF >> /home/${WMA_USER}/.bashrc

alias lll="ls -lathr"
alias ls="ls --color=auto"
alias ll='ls -l --color=auto'

alias condorq='condor_q -format "%i." ClusterID -format "%s " ProcId -format " %i " JobStatus  -format " %d " ServerTime-EnteredCurrentStatus -format "%s" UserLog -format " %s\n" DESIRED_Sites'
alias condorqrunning='condor_q -constraint JobStatus==2 -format "%i." ClusterID -format "%s " ProcId -format " %i " JobStatus  -format " %d " ServerTime-EnteredCurrentStatus -format "%s" UserLog -format " %s\n" DESIRED_Sites'
alias agentenv='source $WMA_ENV_FILE'
agentenv
alias magane=\$manage

# Aliases for Tier0-Ops.
alias runningagent="ps aux | egrep 'couch|wmcore|mysql|beam'"
alias foldersize="du -h --max-depth=1 | sort -hr"

# Better curl command
alias scurl='curl -k --cert ${CERT_DIR}/servicecert.pem --key ${CERT_DIR}/servicekey.pem'

# set WMAgent docker specific bash prompt:
export PS1="(WMAgent.dock) [\u@\h:\w]\$ "

EOF

set +x
echo "Done $stepMsg!" && echo

echo "-----------------------------------------------------------------------"
echo "WMAgent contaner build finished!!" && echo
echo "Have a nice day!" && echo
echo "======================================================================="

exit 0



# if [[ -f $WMA_ENV_FILE ]]; then
#   source $WMA_ENV_FILE
# else
#   echo -e "\n  Could not find $WMA_ENV_FILE, exiting."
#   exit 1
# fi

# TODO: Here we need to
#    * copy/download all the confg && deploy files from https://raw.githubusercontent.com/dmwm/deployment/master/wmagentpy3
#    * preserve  it in a directory outside the host mounted area so that at
#      first/initial container start it could be copied from here instead of downloading it from github on every restart
#    * create the wmagent->wmagentpy3 soft link

# TODO: Same as above for the WMAgent.secrets templates

# ### Enabling couch watchdog; couchdb fix for file descriptors
# echo "*** Enabling couch watchdog ***"
# sed -i "s+RESPAWN_TIMEOUT=0+RESPAWN_TIMEOUT=5+" $WMA_CURRENT_DIR/sw*/$WMA_ARCH/external/couchdb*/*/bin/couchdb
# sed -i "s+exec 1>&-+exec 1>$WMA_CURRENT_DIR/install/couchdb/logs/stdout.log+" $WMA_CURRENT_DIR/sw*/$WMA_ARCH/external/couchdb*/*/bin/couchdb
# sed -i "s+exec 2>&-+exec 2>$WMA_CURRENT_DIR/install/couchdb/logs/stderr.log+" $WMA_CURRENT_DIR/sw*/$WMA_ARCH/external/couchdb*/*/bin/couchdb
# echo "Done!" && echo
