#!/bin/sh
##H Script to perform benchmarks of cmsweb frontends
##H Usage: bench.sh <apache|goauth>
##H

# Check if user is passing least required arguments.
if [ "$#" -lt 1  ]; then
    cat $0 | grep "^##H" | sed -e "s,##H,,g"
    exit 1
fi
btest=$1 # type of test
cmd=~/public/hey_linux
opts="-disable-keepalive"
if [ "$btest" == "goauth" ]; then
    # go-auth
    ghost=https://cmsweb-k8s-testbedsrv.cern.ch:8443
    gfile=/afs/cern.ch/user/v/valya/private/CMSKubernetes/kubernetes/cmsweb/dbs-urls-srv.txt
    ghost="-U $gfile"

    echo "Go-auth 1000/100"
    $cmd $opts -n 1000 -c 100 $ghost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n auth
    echo "Go-auth 1000/200"
    $cmd $opts -n 1000 -c 200 $ghost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n auth
    echo "Go-auth 1000/300"
    $cmd $opts -n 1000 -c 400 $ghost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n auth
    echo "Go-auth 1000/400"
    $cmd $opts -n 1000 -c 400 $ghost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n auth
    echo "Go-auth 1000/500"
    $cmd $opts -n 1000 -c 500 $ghost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n auth

elif [ "$btest" == "apache" ]; then

    # apache FE
    ahost=https://cmsweb-k8s-testbed.cern.ch:8443
    afile=/afs/cern.ch/user/v/valya/private/CMSKubernetes/kubernetes/cmsweb/dbs-urls.txt
    ahost="-U $afile"

    echo "Apache 1000/100"
    $cmd $opts -n 1000 -c 100 $ahost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n default
    echo "Apache 1000/200"
    $cmd $opts -n 1000 -c 200 $ahost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n default
    echo "Apache 1000/300"
    $cmd $opts -n 1000 -c 300 $ahost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n default
    echo "Apache 1000/400"
    $cmd $opts -n 1000 -c 400 $ahost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n default
    echo "Apache 1000/500"
    $cmd $opts -n 1000 -c 500 $ahost 2>&1 | egrep "Requests|response|https"
    kubectl top pods -n default

else
    cat $0 | grep "^##H" | sed -e "s,##H,,g"
    exit 1
fi
