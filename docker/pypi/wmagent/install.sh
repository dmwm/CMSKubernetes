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
while getopts ":v:h" opt; do
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

WMA_TAG_REG="^[0-9]+\.[0-9]+\.[0-9]{1,2}((\.|rc)[0-9]{1,2})?$"
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
pip install wmagent==$WMA_TAG || { err=$?; echo "Failed to install wmagent:$WMA_TAG at $WMA_DEPLOY_IR" ; exit $err ; }
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

# Setup required directories
stepMsg="Creating required directory structure in the WMAgent image"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
mkdir -p ${WMA_DEPLOY_DIR} || true
mkdir -p $WMA_BASE_DIR/wmagent/$WMA_TAG || true
ln -s $WMA_BASE_DIR/wmagent/$WMA_TAG $WMA_CURRENT_DIR

mkdir -p $WMA_ADMIN_DIR $WMA_HOSTADMIN_DIR $WMA_CERTS_DIR $WMA_MANAGE_DIR $WMA_INSTALL_DIR
chmod 755 $WMA_CERTS_DIR

cd $WMA_BASE_DIR
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Downloading all files required for the containder intialisation at the host"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"

# Fix for outdated yui library - A really bad workaround. We should get rid of it ASAP:
wget -nv -P $WMA_DEPLOY_DIR wget http://cmsrep.cern.ch/cmssw/repos/comp/slc7_amd64_gcc630/0000000000000000000000000000000000000000000000000000000000000000/RPMS/cd/cda5f9ef4b33696e67c9e2f995dd5cb6/external+yui+2.9.0-1-1.slc7_amd64_gcc630.rpm
mkdir $WMA_DEPLOY_DIR/yui && cat $WMA_DEPLOY_DIR/external+yui+2.9.0-1-1.slc7_amd64_gcc630.rpm|rpm2archive - |tar --strip-components=13 -xzv --directory $WMA_DEPLOY_DIR/yui

# Download utilitarian scripts:
wget -nv -P $WMA_ADMIN_DIR https://raw.githubusercontent.com/dmwm/WMCore/$WMA_TAG/deploy/checkProxy.py
wget -nv -P $WMA_ADMIN_DIR https://raw.githubusercontent.com/dmwm/WMCore/$WMA_TAG/deploy/restartComponent.sh
wget -nv -P $WMA_ADMIN_DIR https://raw.githubusercontent.com/dmwm/WMCore/$WMA_TAG/deploy/renew_proxy.sh
chmod +x $WMA_ADMIN_DIR/renew_proxy.sh $WMA_ADMIN_DIR/restartComponent.sh

echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Generating and preserving current build id"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
echo $RANDOM |sha256sum |awk '{print $1}' > $WMA_ROOT_DIR/.dockerBuildId
echo "WMA_BUILD_ID:`cat $WMA_ROOT_DIR/.dockerBuildId`"
echo "WMA_BUILD_ID preserved at: $WMA_ROOT_DIR/.dockerBuildId "
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Replace the current /data/manage script coming from 'dmwm-base' image with a symlink link"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
[[ -f /data/manage ]] && rm -f /data/manage && ln -s $WMA_MANAGE_DIR/manage /data/manage
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Creating all runtime aliases for the WMA_USER"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
set -x
cat <<EOF >> /home/${WMA_USER}/.bashrc

alias lll="ls -lathr"
alias ls="ls --color=auto"
alias ll='ls -la --color=auto'

alias condorq='condor_q -format "%i." ClusterID -format "%s " ProcId -format " %i " JobStatus  -format " %d " ServerTime-EnteredCurrentStatus -format "%s" UserLog -format " %s\n" DESIRED_Sites'
alias condorqrunning='condor_q -constraint JobStatus==2 -format "%i." ClusterID -format "%s " ProcId -format " %i " JobStatus  -format " %d " ServerTime-EnteredCurrentStatus -format "%s" UserLog -format " %s\n" DESIRED_Sites'
alias agentenv='source $WMA_ENV_FILE'
agentenv
alias manage=\$manage

# Aliases for Tier0-Ops.
alias runningagent="ps aux | egrep 'couch|wmcore|mysql|beam'"
alias foldersize="du -h --max-depth=1 | sort -hr"

# Better curl command
alias scurl='curl -k --cert ${CERT_DIR}/servicecert.pem --key ${CERT_DIR}/servicekey.pem'

# set WMAgent docker specific bash prompt:
export PS1="(WMAgent-\$WMA_TAG) [\u@\h:\W]\$ "
export WMA_BUILD_ID=\$(cat $WMA_ROOT_DIR/.dockerBuildId)
export WMAGENTPY3_ROOT=\$WMA_INSTALL_DIR/wmagent
export WMAGENTPY3_VERSION=\$WMA_TAG
export PATH=\$WMA_INSTALL_DIR/wmagent/bin\${PATH:+:\$PATH}
EOF

set +x
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Populating cronjob with utilitarian scripts for the WMA_USER"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"

crontab -u $WMA_USER - <<EOF
55 */12 * * * /data/admin/wmagent/renew_proxy.sh
58 */12 * * * python /data/admin/wmagent/checkProxy.py --proxy /data/certs/myproxy.pem --time 120 --send-mail True --mail alan.malta@cern.ch
*/15 * * * *  source /data/admin/wmagent/restartComponent.sh > /dev/null
EOF

echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"


echo "-----------------------------------------------------------------------"
echo "WMAgent contaner build finished!!" && echo
echo "Have a nice day!" && echo
echo "======================================================================="


exit 0
