#!/bin/bash

# Start cvmfs
export VO_CMS_SW_DIR=/cvmfs/cms.cern.ch
source $VO_CMS_SW_DIR/cmsset_default.sh

# Run kerberos configuration
if [ -f /home/cmsusr/monitor.sh ]; then
    /home/cmsusr/monitor.sh
fi

# Run the service
./scripts/build.sh
cd ./scripts
./dqmgui.sh -p 8889

# Start cron deamon
sudo /usr/sbin/crond -n