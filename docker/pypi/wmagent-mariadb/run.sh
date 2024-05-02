#!/bin/bash

# Basic initialization for MariaDB
thisUser=$(id -un)
thisGroup=$(id -gn)
thisUserID=$(id -u)
thisGroupID=$(id -g)
echo "Running MariaDB container with user: $thisUser (ID: $thisUserID) and group: $thisGroup (ID: $thisGroupID)"

export USER=$thisUser
[[ -d ${HOME} ]] || mkdir -p ${HOME}

<<EOF cat >> ~/.bashrc
export USER=$thisUser

alias lll="ls -lathr"
alias ls="ls --color=auto"
alias ll='ls -la --color=auto'

alias manage=$MDB_MANAGE_DIR/manage

# Set command prompt for the running user inside the container
export PS1="(MariaDB-$MDB_TAG) [\u@\h:\W]\$ "
EOF
source ${HOME}/.bashrc

manage init-mariadb  2>&1 | tee -a $MDB_LOG_DIR/run.log
manage start-mariadb 2>&1 | tee -a $MDB_LOG_DIR/run.log

echo "Start sleeping....zzz"
sleep infinity