#!/bin/bash

cd /consistency/cms_consistency/wm

export PYTHON=python3 
export X509_USER_PROXY=/opt/proxy/x509up

./wm_scan.sh /unmerged-config/config.yaml $1  /var/cache/consistency-dump/unmerged

# We don't care about /store/unmerged/logs
mv /var/cache/consistency-dump/unmerged/${1}_files.list.00000.gz /var/cache/consistency-dump/unmerged/$$.gz
zgrep -Ev "^/store/unmerged/logs" /var/cache/consistency-dump/unmerged/$$.gz | gzip > /var/cache/consistency-dump/unmerged/${1}_files.list.00000.gz
rm /var/cache/consistency-dump/unmerged/$$.gz