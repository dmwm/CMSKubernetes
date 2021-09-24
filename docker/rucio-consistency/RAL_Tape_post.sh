#!/usr/bin/env bash

# This script should run some time after the RAL disk dump script finishes at RAL
cp /opt/proxy/x509up /tmp/x509up
chmod 600 /tmp/x509up
export X509_USER_PROXY=/tmp/x509up
cd /consistency/cms_consistency/RAL
./RAL_compare.sh /config/config.yaml /opt/rucio/etc/rucio.cfg T1_UK_RAL_Tape /var/cache/consistency-temp/ /var/cache/consistency-dump/
