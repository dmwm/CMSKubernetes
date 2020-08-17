#!/bin/sh

docker build -t cmssw/rucio-consistency .
docker push cmssw/rucio-consistency 
