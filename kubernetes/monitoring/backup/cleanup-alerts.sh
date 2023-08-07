#!/bin/sh
amtool=/cvmfs/cms.cern.ch/cmsmon/alert
services="SSB GGUS"
date="2021-03-20T20:52:00Z"
hosts="http://cms-monitoring-ha1.cern.ch:30093 http://cms-monitoring-ha2.cern.ch:30093 http://cms-monitoring.cern.ch:30093"
for srv in $services; do
    for amurl in $hosts; do
    echo "clean-up $amurl service=$srv"
        $amtool -service=$srv | grep Undefined | \
            awk '{print ""AMTOOL" -ends=\""DATE"\" -name="$1" -amurl="AMURL""}' \
            DATE=$date AMURL=$amurl AMTOOL=$amtool | /bin/sh
    done
done
