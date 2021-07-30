#! /bin/sh 

export DAEMON_NAME=cms-globus-${INSTANCE}

# Rucio server, daemons, and daemons for analysis

helm3 install $DAEMON_NAME --values cms-rucio-common.yaml,cms-rucio-daemons.yaml,${INSTANCE}-globus-daemons.yaml,${INSTANCE}-db.yaml,${INSTANCE}-release.yaml $REPO/rucio-daemons

