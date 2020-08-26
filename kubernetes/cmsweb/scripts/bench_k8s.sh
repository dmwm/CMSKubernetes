#!/bin/bash
##H Usage: bench_k8s.sh <url> <dbs_instance=int>
##H

# define help
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi

url=$1
run=$2
# defint bench tool
tool=${BENCH_TOOL:-/afs/cern.ch/user/v/valya/public/hey_linux}

# dbs instance, default is preproduction dbs instance
inst=int
if [ $# -eq 3 ]; then
    inst=$3
fi
urls="$url/couchdb $url/acdcserver/_all_docs $url/reqmgr2/data/info $url/dbs/$inst/global/DBSReader/datasets?dataset=/ZMM*/*/* $url/das $url/workqueue/index.html $url/phedex $url/phedex/datasvc/doc $url/t0_reqmon/data/info $url/crabserver/preprod/info $url/crabcache/info $url/wmstatsserver/data/info $url/wmstats/index.html $url/t0wmadatasvc/replayone/hello"

X509_USER_KEY=$HOME/.globus/userkey.pem
X509_USER_CERT=$HOME/.globus/usercert.pem


opts="-n 10 -c 5"
echo
echo "$url"
    total=0
        for (( i=1; i<=${run}; i++ ))
        do
        res=`$tool $opts "$url" | grep Requests`
        result="${res/'Requests/sec:'/}"
#       echo "result=" $result
        total=$(bc -l <<<"${result}+${total}")
#       echo "total=" $total
    done
    echo $(bc -l <<<"${total}/${run}")
for u in $urls; do
    echo "$u"
    total=0
        for (( i=1; i<=${run}; i++ ))
        do
        res=`$tool $opts "$u" | grep Requests`
        result="${res/'Requests/sec:'/}"
#       echo "result=" $result
        total=$(bc -l <<<"${result}+${total}")
#       echo "total=" $total
    done
    echo $(bc -l <<<"${total}/${run}")
done
