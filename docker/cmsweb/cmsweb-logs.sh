#!/bin/bash

usage="cmsweb-logs.sh <ssh-public-key> </path/local-log-area> <user@host:/path/remote-log-area>"
if [ $# -ne 3 ]; then
    echo "Usage: $usage"
    exit 1
fi

sshPubKey=$1
localLogArea=$2
remoteLogArea=$3

if [ -f $sshPubKey ]; then
    rsync -rm -e "ssh -c aes128-ctr -i $sshPubKey" \
        --append -f '+s */' -f '+s *.txt' -f '+s *.log*' -f '-s /***/*' \
        $localLogArea $remoteLogArea

    # Delete files not modified in the last 7 days
    find $localLogArea -type f -mtime +6 -exec rm -f '{}' \;
fi
