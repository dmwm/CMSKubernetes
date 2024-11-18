#!/bin/bash

# add WMCore repository, if in Jenkins
if [[ -z "${BUILD_ID}" ]]; then
    echo "No BUILD_ID set"
else
    echo "BUILD_ID set, cloning dmwm/WMCore"
    git clone https://github.com/dmwm/WMCore

    # give proper permissions to home directory
    chown -R ${MY_ID}:${MY_GROUP} /home/cmsbld

    USERN=$(id -un ${MY_ID})

    su - $USERN
fi

pushd /home/cmsbld

# clone jenkins-test scripts
git clone https://github.com/d-ylee/jenkins-test
popd

$@