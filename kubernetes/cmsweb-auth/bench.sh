#!/bin/sh
cmd=~/public/hey_linux
# apache FE
ahost=https://cmsweb-auth.cern.ch
#ahost=https://cmsweb-k8s-testbed.cern.ch/httpgo
#ahost=https://cmsweb-k8s-testbed.cern.ch
# go FE
#ghost=https://cmsweb-auth.cern.ch:8443/httpgo
ghost=https://cmsweb-auth.cern.ch:8443

echo "Go-auth 1000/100"
$cmd -n 1000 -c 100 $ghost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Go-auth 1000/200"
$cmd -n 1000 -c 200 $ghost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Go-auth 1000/300"
$cmd -n 1000 -c 400 $ghost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Go-auth 1000/400"
$cmd -n 1000 -c 400 $ghost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Go-auth 1000/500"
$cmd -n 1000 -c 500 $ghost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth

echo "Apache 1000/100"
$cmd -n 1000 -c 100 $ahost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Apache 1000/200"
$cmd -n 1000 -c 200 $ahost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Apache 1000/300"
$cmd -n 1000 -c 300 $ahost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Apache 1000/400"
$cmd -n 1000 -c 400 $ahost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
echo "Apache 1000/500"
$cmd -n 1000 -c 500 $ahost 2>&1 | egrep "Requests|response|https"
kubectl top pods -n auth
