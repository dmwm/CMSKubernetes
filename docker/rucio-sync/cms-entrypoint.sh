#! /bin/bash

if [ -f /opt/rucio/etc/rucio.cfg ]; then
    echo "rucio.cfg already mounted."
else
    echo "rucio.cfg not found. will generate one."
    j2 /tmp/rucio.cfg.j2 | sed '/^\s*$/d' > /opt/rucio/etc/rucio.cfg
fi
while true
do
    echo "Starting a new sync at $(date)"
    ~/scripts/new_sync.py --config /etc/sync-config/site-sync.yaml
    sleep 60
done
