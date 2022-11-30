#!/bin/bash

# Start cvmfs
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh

# Run kerberos configuration
if [ -f /home/cmsusr/monitor.sh ]; then
    echo "MONITOR FILE FOUND"
    bash /home/cmsusr/monitor.sh
else
    echo "MONITOR FILE NOT FOUND"
fi

# Run the service
./scripts/build.sh
cd ./scripts
./dqmgui.sh -p 8889

# Start cron deamon
/usr/sbin/crond -n
