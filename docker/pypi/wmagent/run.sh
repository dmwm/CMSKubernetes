#!/bin/bash

_service_gracefull_exit() {
    ppid=$$
    echo "Full list of currently running processes:"
    ps auxf

    echo -e "\nStopping WMAgent"
    manage stop-agent

    echo -e "\nList of all child processes of pid $ppid upon agent graceful exit:"
    pslist $ppid

    echo -e "\nKilling children processes recursively"
    rkill -9 $ppid

    echo -e "\nFull list of currently running processes after killing children:"
    ps auxf
}

# Trap SIGTERM signal (e.g.: when doing docker stop)
trap _service_gracefull_exit SIGTERM

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

cp -f ${WMA_DEPLOY_DIR}/etc/wmagent_bashrc $HOME/.bashrc
source $HOME/.bashrc

echo "Start initialization"
$WMA_ROOT_DIR/init.sh | tee -a $WMA_LOG_DIR/init.log || true

echo "Start sleeping now ...zzz..."
sleep infinity &
wait
