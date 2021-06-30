#!/bin/bash

cd /consistency/cms_consistency/site_cmp3

cp /opt/proxy/x509up /tmp/x509up
chmod 600 /tmp/x509up
export X509_USER_PROXY=/tmp/x509up

export PYTHON=python3

./site_cmp3.sh \
  /config/config.yaml \
  /opt/rucio/etc/rucio.cfg \
  $1 \
  /var/cache/consistency-temp \
  /var/cache/consistency-dump \
  /tmp/x509up



