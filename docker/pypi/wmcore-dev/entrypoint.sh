#!/bin/bash

# add WMCore repository, if in Jenkins
if [[ -z "${BUILD_ID}" ]]; then
    echo "No BUILD_ID set, we in dev mode"
else
    echo "BUILD_ID set, setting up for CI/CD"

    # give proper ownership and permissions to home directory
    chown -R ${MY_ID}:${MY_GROUP} /home/cmsbld
    chmod -R 755 /home/cmsbld

    pushd /home/cmsbld

    # clone main repo
    git clone https://github.com/${WMCORE_ORG:-dmwm}/WMCore

    # clone jenkins-test scripts
    git clone --depth 1 --branch ${WMCORE_JENKINS_TAG:-master} https://github.com/${WMCORE_JENKINS_ORG:-dmwm}/WMCore-Jenkins

    cp -r WMCore-Jenkins/TestScripts .
    cp -r WMCore-Jenkins/ContainerScripts .
    cp -r WMCore-Jenkins/etc .

    popd

fi

$@
