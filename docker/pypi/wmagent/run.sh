#!/bin/bash

### Basic initialization wrapper for WMAgent to serve as the main entry point for the WMAgent Docker container
wmaUser=$(id -un)
wmaGroup=$(id -gn)
wmaUserID=$(id -u)
wmaGroupID=$(id -g)

echo "Running WMAgent container with user: $wmaUser (ID: $wmaUserID) and group: $wmaGroup (ID: $wmaGroupID)"

echo "Setting up bashrc for user: $wmaUser under home directory: $HOME"
export WMA_USER=$wmaUser
export USER=$wmaUser
[[ -d ${HOME} ]] || mkdir -p ${HOME}

mv ${WMA_CONFIG_DIR}/etc/wmagent_bashrc $HOME/.bashrc
source $HOME/.bashrc

echo "Start initialization"
$WMA_ROOT_DIR/init.sh | tee -a $WMA_LOG_DIR/init.log || true

echo "Start sleeping now ...zzz..."
sleep infinity
