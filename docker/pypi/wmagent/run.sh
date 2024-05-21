#!/bin/bash

_find_child_pss() {
    # An auxiliary function to find all processes forked from the shell parrent
    # of the current process
    # :param $1: The name of a variable to which the process list would be asssigned
    # :return:   A list of child processes forked from the current one
    local -n outList=$1;
    local currPid=$$
    outList=$(cat  /proc/$currPid/task/*/children)
}

_service_gracefull_exit() {
    # An auxiliary function to handle the WMAgent service graceful exit
    local childPss

    echo "Full list of currently running processes:"
    ps auxf

    echo "Stopping WMAgent"
    manage stop-agent

    _find_child_pss childPss
    echo "List of all child processes upon agent graceful exit: $childPss"

    echo "Killing all chilld Processes ..."
    for proc in $childPss
    do
        echo killing process $proc
        kill -9 $proc
    done
}

# Here to define the signal we are about to trap for handling WMAgent graceful exit
# NOTE: curently (just for testing purposes) we stick to `SIGUSR1` later we should
#       move to SIGTERM and/or SIGKILL. In order to test the current implementation execute:
#       docker exec -it wmagent bash
#       kill -s 10 1
trap _service_gracefull_exit SIGUSR1

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
sleep infinity  &
wait
