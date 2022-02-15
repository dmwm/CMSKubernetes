#!/bin/bash

cd /consistency/cms_consistency/wm

cp /opt/proxy/x509up /tmp/x509up
chmod 600 /tmp/x509up
export X509_USER_PROXY=/tmp/x509up

export PYTHON=python3

./wm_scan.sh /unmerged-config/config.yaml $1  /var/cache/consistency-dump/unmerged
