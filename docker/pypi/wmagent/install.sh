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
echo " - WMAgent Release Cycle      : $WMA_VER_RELEASE"
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
curl  https://yui.github.io/yui2/archives/yui_2.9.0.zip -o $WMA_DEPLOY_DIR/yui_2.9.0.zip || { err=$?; echo "Error downloading yui_2.9.0.zip"; exit $err ; }
unzip -d $WMA_DEPLOY_DIR $WMA_DEPLOY_DIR/yui_2.9.0.zip yui/build/*
rm -f $WMA_DEPLOY_DIR/yui_2.9.0.zip

echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

stepMsg="Generating and preserving current build id"
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"

echo $WMA_VER_RELEASE | sha256sum | awk '{print $1}' > $WMA_ROOT_DIR/.wmaBuildId
echo "WMA_BUILD_ID:`cat $WMA_ROOT_DIR/.wmaBuildId`"
echo "WMA_BUILD_ID preserved at: $WMA_ROOT_DIR/.wmaBuildId "

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
    echo "Edit \$WMA_ENV_FILE script to point to \$WMA_ROOT_DIR"
    sed -i "s|/data/|\$WMA_ROOT_DIR/|g" $WMA_ENV_FILE

    echo "Edit \$WMA_ENV_FILE script to point to the correct install, config and manage"
    sed -i "s|install=.*|install=\$WMA_INSTALL_DIR|g" $WMA_ENV_FILE
    sed -i "s|config=.*|config=\$WMA_CONFIG_DIR|g" $WMA_ENV_FILE
    sed -i "s|manage=.*|manage=\$WMA_MANAGE_DIR/manage|g" $WMA_ENV_FILE

    cat <<EOF >> $WMA_ENV_FILE

export WMA_BUILD_ID=\$(cat \$WMA_ROOT_DIR/.wmaBuildId)
export WMCORE_ROOT=\$WMA_DEPLOY_DIR
export WMAGENT_CONFIG=\$WMA_CONFIG_FILE
export WMAGENTPY3_ROOT=\$WMA_INSTALL_DIR
export WMAGENTPY3_VERSION=\$WMA_TAG
export CRYPTOGRAPHY_ALLOW_OPENSSL_102=true
export YUI_ROOT=$WMA_DEPLOY_DIR/yui/
export PATH=\$WMA_INSTALL_DIR/bin\${PATH:+:\$PATH}
export PATH=\$WMA_DEPLOY_DIR/bin\${PATH:+:\$PATH}
export USER=\$(id -un)
export WMA_USER=\$(id -un)
EOF
}


stepMsg="Tweaking runtime environment."
echo "-----------------------------------------------------------------------"
echo "Start $stepMsg"
tweakEnv || { err=$?; echo ""; exit $err ; }

source $WMA_ENV_FILE
source $WMA_DEPLOY_DIR/bin/manage-common.sh
echo "Done $stepMsg!" && echo
echo "-----------------------------------------------------------------------"

echo "-----------------------------------------------------------------------"
echo "WMAgent image build finished!!" && echo
echo "Have a nice day!" && echo
echo "======================================================================="


exit 0
