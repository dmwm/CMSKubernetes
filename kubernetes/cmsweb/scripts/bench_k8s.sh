#!/bin/bash
##H Usage: bench_k8s.sh <url> <dbs_instance=int>
##H

# define help
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi

# defint bench tool
tool=${BENCHK8S:-/afs/cern.ch/user/v/valya/public/hey_linux}

# define list of urls to test
url=${CMSK8S:-https://cmsweb-test.cern.ch}
if [ -n "$1" ]; then
    url=$1
fi

# dbs instance, default is preproduction dbs instance
inst=int
if [ $# -eq 2 ]; then
    inst=$2
fi

urls="$url/couchdb $url/acdcserver/_all_docs $url/alertscollector/_all_docs $url/reqmgr2/data/info $url/dbs/$inst/global/DBSReader/datasets?dataset=/ZMM*/*/* $url/das $url/workqueue/index.html $url/phedex $url/phedex/datasvc/doc $url/confdb/ $url/t0_reqmon/data/info $url/crabserver/preprod/info $url/crabcache/info $url/wmstatsserver/data/info $url/wmstats/index.html $url/t0wmadatasvc/replayone/hello"

X509_USER_KEY=$HOME/.globus/userkey.pem
X509_USER_CERT=$HOME/.globus/usercert.pem

# DO NOT MODIFY BELOW THIS LINE

# perform tests with user key/cert
opts="-n 10 -c 5"
echo
res=`$tool $opts "$url" | grep Requests`
echo "$url $res"
for u in $urls; do
    res=`$tool $opts "$u" | grep Requests`
    echo "$u $res"
done
