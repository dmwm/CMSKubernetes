#!/bin/bash

# Basic initialization for CouchDB
thisUser=$(id -un)
thisGroup=$(id -gn)
thisUserID=$(id -u)
thisGroupID=$(id -g)
echo "Running CouchDB container with user: $thisUser (ID: $thisUserID) and group: $thisGroup (ID: $thisGroupID)"

export USER=$thisUser
[[ -d ${HOME} ]] || mkdir -p ${HOME}

<<EOF cat >> ~/.bashrc
export USER=$thisUser

alias lll="ls -lathr"
alias ls="ls --color=auto"
alias ll='ls -la --color=auto'
alias scurl='curl -k --cert ${COUCH_CERTS_DIR}/servicecert.pem --key ${COUCH_CERTS_DIR}/servicekey.pem'

alias manage=$COUCH_MANAGE_DIR/manage

# Set command prompt for the running user inside the container
export PS1="(CouchDB-$TAG) [\u@\h:\W]\$ "
EOF
source ${HOME}/.bashrc

manage init      | tee -a $COUCH_LOG_DIR/run.log
manage start     | tee -a $COUCH_LOG_DIR/run.log
manage pushapps  | tee -a $COUCH_LOG_DIR/run.log

echo "start sleeping....zzz"
sleep infinity

# # start the service
# manage start
