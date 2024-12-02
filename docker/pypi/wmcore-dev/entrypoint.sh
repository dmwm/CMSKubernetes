#!/bin/bash

# add WMCore repository, if in Jenkins
if [[ -z "${BUILD_ID}" ]]; then
    echo "No BUILD_ID set"
else
    echo "BUILD_ID set, setting up for CI/CD"
    # give proper permissions to home directory
    chown -R ${MY_ID}:${MY_GROUP} /home/cmsbld

    USERN=$(id -un ${MY_ID})

    su - $USERN << EOSU
    git clone https://github.com/dmwm/WMCore

    pushd /home/cmsbld

    # clone jenkins-test scripts
    git clone https://github.com/dmwm/WMCore-Jenkins .
    popd
EOSU
fi

$@