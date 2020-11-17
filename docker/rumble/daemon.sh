#!/bin/bash

# Copy current logs to history for debugging
cat /data/server.log >> /data/server.log.history

# Get current running spark server pid
nohup_pid=`pgrep -f "spark-rumble"`
kill -9 $nohup_pid
echo "Running nohup process killed. Pid: "$nohup_pid""
/bin/bash /data/run_rumble.sh
