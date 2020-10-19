#!/bin/bash

usage="cmsweb-logs.sh <keytab> </path/local-log-area> <user@host:/path/remote-log-area>"
if [ $# -ne 3 ]; then
    echo "Usage: $usage"
    exit 1
fi

keytab=$1
localLogArea=$2
remoteLogArea=$3

principal=`klist -k "$keytab" | tail -1 | awk '{print $2}'`
echo "principal=$principal" 2>&1 1>& /dev/null
kinit $principal -k -t "$keytab" 2>&1 1>& /dev/null
if [ $? == 1 ]; then
    echo "Unable to perform kinit" >> $log 2>&1
    exit 1
fi
klist -k "$keytab" 2>&1 1>& /dev/null

if [ -f $sshPubKey ]; then
    rsync -rm \
        --append -f '+s */' -f '+s *.txt' -f '+s *.log*' -f '-s /***/*' \
        $localLogArea $remoteLogArea

    # Delete files not modified in the last 7 days
    find $localLogArea -type f -mtime +6 -exec rm -f '{}' \;
fi
