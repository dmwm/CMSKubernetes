#!/bin/bash
##H Usage: test_k8s.sh <url> <dbs_instance=int>
##H

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi

url=$1

# dbs instance, default is preproduction dbs instance
inst=int
if [ $# -eq 2 ]; then
    inst=$2
fi

# scram architecture
arch=${SCRAM_ARCH:-slc7_amd64_gcc700}

urls="$url/couchdb $url/acdcserver/_all_docs $url/reqmgr2/data/info $url/dbs/$inst/global/DBSReader/datasets?dataset=/ZMM*/*/* $url/das $url/workqueue/index.html $url/phedex $url/phedex/datasvc/doc $url/t0_reqmon/data/info $url/crabserver/preprod/info $url/wmstatsserver/data/info $url/wmstats/index.html $url/t0wmadatasvc/replayone/hello $url/exitcodes $url/wmarchive/data $url/ms-transferor/data/status $url/ms-monitor/data/status $url/ms-output/data/status $url/ms-rulecleaner/data/status $url/ms-unmerged/data/status?rse_type=t1 $url/ms-unmerged/data/status?rse_type=t2t3 $url/ms-unmerged/data/status?rse_type=t2t3us"

X509_USER_KEY=$HOME/.globus/userkey.pem
X509_USER_CERT=$HOME/.globus/usercert.pem

# DO NOT MODIFY BELOW THIS LINE

# define curl options to show only HTTP code
opts="-L -s -o /dev/null -w \"%{http_code}\""

# perform tests with user key/cert
echo
echo "### tests with $X509_USER_KEY and $X509_USER_CERT"
for u in $urls; do
    code=`curl $opts --key $X509_USER_KEY --cert $X509_USER_CERT -H "Accept: application/json" "$u"`
    echo "$u HTTP code: $code"
done

# setup CMSSW version of curl
echo
echo "### setup CMSSW environment since we need special curl build"
cdir=/cvmfs/cms.cern.ch/$arch/external/curl
cver=`ls $cdir | sort -n | tail -1`
echo "### use $cdir/$cver"
source $cdir/$cver/etc/profile.d/init.sh
curl --version

echo "### tests with X509_USER_PROXY"
unset X509_USER_PROXY
voms-proxy-init -voms cms -rfc
export X509_USER_PROXY=/tmp/x509up_u`id -u`

echo
echo "### tests with $X509_USER_PROXY"
for u in $urls; do
    code=`curl $opts --key $X509_USER_PROXY --cert $X509_USER_PROXY -H "Accept: application/json" "$u"`
    echo "$u HTTP code: $code"
done
