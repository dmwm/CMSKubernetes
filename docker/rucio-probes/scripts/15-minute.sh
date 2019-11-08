#! /bin/bash

echo "Running things to be run every 15 minutes"

cd /root/probes/common

./check_transfer_queues_status


sleep 1000