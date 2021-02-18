#!/usr/bin/env bash

# This script should start and finish before the RAL disk dump starts at RAL

cd /consistency/cms_consistency/RAL
./RAL_dbdump.sh /config/config.yaml /opt/rucio/etc/rucio.cfg T1_UK_RAL_Disk /var/cache/consistency-temp/ /var/cache/consistency-dump/
