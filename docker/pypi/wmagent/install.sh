#!/bin/bash

### This script is used to deploy the WMAgent pypi package inside a Docker image
### based on the WMAgent version/tag provided at build time.
### * Patches can be applied when the agent container is started.
### * Configuration changes are made when the container is initialized for the first time with `init.sh`.
###
### It takes a single parameter as first (and only) argument - The WMA_TAG
### Example: install.sh -t 2.2.0.2

pythonLib=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")

help(){
    echo -e $1
    cat <<EOF

The basic WMAgent deployment script for Docker image creation:
Usage: install.sh -t <wmagent_tag>

    -t <wmagent_tag>    The WMAgent version/tag to be used for the Docker image creation

Example: ./install.sh -t 2.2.0.2

EOF
}

usage(){
    help $1
    exit 1
}

WMA_TAG=None

### Argument parsing:
while getopts ":t:h" opt; do
    case ${opt} in
        t) WMA_TAG=$OPTARG ;;
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
echo " - Python  Version            : $(python --version)"
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
echo "-----------------------------------------------------------------------"

# Setup required directories
stepMsg="Creating required directory structure in the WMAgent image"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
mkdir -p $WMA_DEPLOY_DIR  || true
mkdir -p $WMA_CURRENT_DIR || true
ln -s $WMA_CURRENT_DIR $WMA_BASE_DIR/current

mkdir -p $WMA_ADMIN_DIR $WMA_CERTS_DIR $WMA_MANAGE_DIR $WMA_INSTALL_DIR $WMA_AUTH_DIR $WMA_STATE_DIR $WMA_CONFIG_DIR $WMA_LOG_DIR
chmod 755 $WMA_CERTS_DIR

cd $WMA_BASE_DIR
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Downloading all files required for the containder intialisation at the host"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"

# Fix for outdated yui library - A really bad workaround. We should get rid of it ASAP:
wget -nv -P $WMA_DEPLOY_DIR  https://yui.github.io/yui2/archives/yui_2.9.0.zip || { err=$?; echo "Error downloading yui_2.9.0.zip"; exit $err ; }
unzip -d $WMA_DEPLOY_DIR $WMA_DEPLOY_DIR/yui_2.9.0.zip yui/build/*
rm -f $WMA_DEPLOY_DIR/yui_2.9.0.zip

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

tweakEnv(){
    # A function to apply environment tweaks for the docker image
    echo "-------------------------------------------------------"
    echo "Edit \$WMA_ENV_FILE script to point to \$WMA_ROOT_DIR"
    sed -i "s|/data/|\$WMA_ROOT_DIR/|g" $WMA_ENV_FILE

    echo "-------------------------------------------------------"
    echo "Edit \$WMA_ENV_FILE script to point to the correct install, config and manage"
    sed -i "s|install=.*|install=\$WMA_INSTALL_DIR|g" $WMA_ENV_FILE
    sed -i "s|config=.*|config=\$WMA_CONFIG_DIR|g" $WMA_ENV_FILE
    sed -i "s|manage=.*|manage=\$WMA_MANAGE_DIR/manage|g" $WMA_ENV_FILE
    sed -i "s|RUCIO_HOME=.*|RUCIO_HOME=\$WMA_CONFIG_DIR|g" $WMA_ENV_FILE

    echo "Edit $WMA_DEPLOY_DIR/deploy/renew_proxy.sh script to point to \$WMA_ROOT_DIR"
    sed -i "s|/data/|\$WMA_ROOT_DIR/|g" $WMA_DEPLOY_DIR/deploy/renew_proxy.sh
    sed -i "s|source.*env\.sh|source \$WMA_ENV_FILE|g" $WMA_DEPLOY_DIR/deploy/renew_proxy.sh
    echo "-------------------------------------------------------"

    cat <<EOF >> $WMA_ENV_FILE

export WMA_BUILD_ID=\$(cat \$WMA_ROOT_DIR/.dockerBuildId)
export WMCORE_ROOT=\$WMA_DEPLOY_DIR
export WMAGENTPY3_ROOT=\$WMA_INSTALL_DIR
export WMAGENTPY3_VERSION=\$WMA_TAG
export CRYPTOGRAPHY_ALLOW_OPENSSL_102=true
export YUI_ROOT=$WMA_DEPLOY_DIR/yui/
export PATH=\$WMA_INSTALL_DIR/bin\${PATH:+:\$PATH}
export PATH=\$WMA_DEPLOY_DIR/bin\${PATH:+:\$PATH}
EOF
}


stepMsg="Tweaking runtime environment for user: $WMA_USER"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
tweakEnv || { err=$?; echo ""; exit $err ; }
cat <<EOF >> /home/${WMA_USER}/.bashrc

alias lll="ls -lathr"
alias ls="ls --color=auto"
alias ll='ls -la --color=auto'

alias condorq='condor_q -format "%i." ClusterID -format "%s " ProcId -format " %i " JobStatus  -format " %d " ServerTime-EnteredCurrentStatus -format "%s" UserLog -format " %s\n" DESIRED_Sites'
alias condorqrunning='condor_q -constraint JobStatus==2 -format "%i." ClusterID -format "%s " ProcId -format " %i " JobStatus  -format " %d " ServerTime-EnteredCurrentStatus -format "%s" UserLog -format " %s\n" DESIRED_Sites'
alias agentenv='source $WMA_ENV_FILE'
alias manage=\$WMA_MANAGE_DIR/manage

# Aliases for Tier0-Ops.
alias runningagent="ps aux | egrep 'couch|wmcore|mysql|beam'"
alias foldersize="du -h --max-depth=1 | sort -hr"

# Better curl command
alias scurl='curl -k --cert ${CERT_DIR}/servicecert.pem --key ${CERT_DIR}/servicekey.pem'

# set WMAgent docker specific bash prompt:
export PS1="(WMAgent-\$WMA_TAG) [\u@\h:\W]\$ "

source $WMA_ENV_FILE
source $WMA_DEPLOY_DIR/bin/manage-common.sh
EOF
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Populating cronjob with utilitarian scripts for the WMA_USER"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"

# TODO: These executable flags we should consider fixing them for all *.sh
#       scripts under the /deploy top level area in the WMCore github repository
chmod +x $WMA_DEPLOY_DIR/deploy/renew_proxy.sh $WMA_DEPLOY_DIR/deploy/restartComponent.sh

crontab -u $WMA_USER - <<EOF
55 */12 * * * $WMA_MANAGE_DIR/manage renew-proxy
58 */12 * * * python $WMA_DEPLOY_DIR/deploy/checkProxy.py --proxy /data/certs/myproxy.pem --time 120 --send-mail True --mail alan.malta@cern.ch
*/15 * * * *  source $WMA_DEPLOY_DIR/deploy/restartComponent.sh > /dev/null
EOF

echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"


echo "-----------------------------------------------------------------------"
echo "WMAgent contaner build finished!!" && echo
echo "Have a nice day!" && echo
echo "======================================================================="


exit 0
