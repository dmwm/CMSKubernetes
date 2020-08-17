#!/bin/bash

cd /consistency/cms_consistency/site_cmp3

export PYTHON=python3 

./site_cmp3.sh \
  /config/config.yaml \
  /opt/rucio/etc/rucio.cfg \
  $1 \
  /var/cache/consistency-temp \
  /var/cache/consistency-dump \
  /opt/proxy/x509up                   



