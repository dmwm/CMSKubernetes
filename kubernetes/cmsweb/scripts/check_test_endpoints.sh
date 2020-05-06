#!/bin/bash
##H Usage: check_test_endpoints.sh <url>
##H

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi

url=$1

# scram architecture
arch=${SCRAM_ARCH:-slc7_amd64_gcc700}

urls="$url/ $url/acdcserver/_all_docs $url/das/request?view=list&limit=50&instance=prod%2Fglobal&input=dataset%3D%2FZMM*%2F*%2F* $url/phedex/datasvc/json/dev/agents $url/t0_reqmon/data/requestcache $url/crabserver/preprod/workflow $url/crabcache/info?subresource=basicquota $url/wmstatsserver/data/filtered_requests $url/exitcodes $url/couchdb $url/reqmgr2/data/info $url/wmstats/index.html $url/confdb/ $url/workqueue/index.html $url/dbs/int/global/DBSReader/datatiers?data_tier_name=RECO $url/dbs/int/global/DBSReader/datasets?dataset=/ZMM/Summer11-DESIGN42_V11_428_SLHC1-v1/* $url/dbs/int/global/DBSReader/datatypes $url/dbs/int/global/DBSReader/serverinfo $url/t0wmadatasvc/replayone/hello "

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
