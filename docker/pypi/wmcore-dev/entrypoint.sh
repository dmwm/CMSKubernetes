#!/bin/bash

# add WMCore repository, if in Jenkins
if [[ -z "${BUILD_ID}" ]]; then
    echo "No BUILD_ID set, we in dev mode"
else
    echo "BUILD_ID set, setting up for CI/CD"
    # give proper permissions to home directory
    chown -R ${MY_ID}:${MY_GROUP} /home/cmsbld

    USERN=$(id -un ${MY_ID})

    su - $USERN << EOSU

    pushd /home/cmsbld

    # clone main repo
    git clone https://github.com/dmwm/WMCore

    # clone jenkins-test scripts
    git clone https://github.com/dmwm/WMCore-Jenkins

    # TODO: Move scripts to a more sensible location in WMCore-Jenkins
    cp -r WMCore-Jenkins/docker/wmcore-dev/TestScripts .
    cp -r WMCore-Jenkins/docker/wmcore-dev/ContainerScripts .
    cp -r WMCore-Jenkins/docker/wmcore-dev/etc .
    popd
EOSU
fi

$@