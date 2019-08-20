#!/bin/bash
# define help
usage="Usage: tests.sh <url>"
if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ]; then
    echo $usage
    exit 1
fi

# define list of urls to test
if [ $# -eq 1 ]; then
    url=$1
else
    url=${CMSK8S:-https://cmsweb-test.cern.ch}
fi

# dbs instance
inst=int # preproduction

urls="$url/couchdb $url/acdcserver/_all_docs $url/alertscollector/_all_docs $url/reqmgr2/data/info $url/dbs/$inst/global/DBSReader/datasets?dataset=/ZMM*/*/* $url/das $url/workqueue/index.html $url/phedex $url/phedex/datasvc/doc $url/confdb/ $url/t0_reqmon/data/info $url/crabserver/preprod/info $url/crabcache/info $url/wmstatsserver/data/info $url/wmstats/index.html $url/t0wmadatasvc/replayone/hello"

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
cdir=/cvmfs/cms.cern.ch/$SCRAM_ARCH/external/curl
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
