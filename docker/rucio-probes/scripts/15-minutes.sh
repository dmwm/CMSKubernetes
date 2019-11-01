#! /bin/bash

echo "Running things to be run every 15 minutes"

set -x


j2 /tmp/rucio.cfg.j2 | sed '/^\s*$/d' > /opt/rucio/etc/rucio.cfg

ls /opt/rucio/etc

cd /root/probes/common

# Rewrite script(s) until a generic version is available from Dimitrious
sed -i -E "s/atlas_rucio.//g"  check_transfer_queues_status

./check_transfer_queues_status

sleep 60