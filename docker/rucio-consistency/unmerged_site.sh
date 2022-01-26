#!/bin/bash

cd /consistency/cms_consistency/wm

export PYTHON=python3 
export X509_USER_PROXY=/opt/proxy/x509up

./wm_scan.sh /unmerged-config/config.yaml $1  /var/cache/consistency-dump/unmerged
