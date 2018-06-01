#!/bin/bash
echo "prune all images"
#docker system prune -f -a
echo "### build cmssw/cmsweb"
docker build -t cmssw/cmsweb cmsweb
docker push cmssw/cmsweb

echo "### build cmssw/frontend"
docker build -t cmssw/frontend frontend
docker push cmssw/frontend

echo "### build cmssw/exporters"
docker build -t cmssw/exporters exporters
docker push cmssw/exporters

echo "### build cmssw/das2go"
docker build -t cmssw/das2go das2go
docker push cmssw/das2go

echo "### build cmssw/dbs2go"
docker build -t cmssw/dbs2go dbs2go
docker push cmssw/dbs2go

echo "### build cmssw/dbs"
docker build -t cmssw/dbs dbs
docker push cmssw/dbs

echo "### build cmssw/couchdb"
docker build -t cmssw/couchdb couchdb
docker push cmssw/couchdb

echo "### build cmssw/reqmgr"
docker build -t cmssw/reqmgr reqmgr
docker push cmssw/reqmgr

echo "### build cmssw/reqmon"
docker build -t cmssw/reqmon reqmon
docker push cmssw/reqmon

echo "### build cmssw/workqueue"
docker build -t cmssw/workqueue workqueue
docker push cmssw/workqueue

echo "### build veknet/tfaas"
docker build -t veknet/tfaas tfaas
docker push veknet/tfaas
