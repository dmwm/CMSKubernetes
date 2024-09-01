#!/bin/bash
##H Usage: test_k8s.sh <base_url>
##H

if [ "$1" == "-h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ] || [ "$1" == "help" ] || [ "$1" == "" ]; then
    perl -ne '/^##H/ && do { s/^##H ?//; print }' < $0
    exit 1
fi

X509_USER_KEY=$HOME/.globus/userkey.pem
X509_USER_CERT=$HOME/.globus/usercert.pem

base_url=$1

# Function to perform the request with automatic redirect following
perform_request() {
    local target_url="$1"
    final_status_code=$(curl -L -i --key $X509_USER_KEY --cert $X509_USER_CERT -o /dev/null -w '%{http_code}' -s "$target_url")
    echo "$target_url HTTP code: $final_status_code"
}

# CouchDB
echo "CouchDB:"
urls_couchdb="
/couchdb/
"
for u in $urls_couchdb; do
    perform_request "${base_url}${u}"
done
echo

# Crabserver
echo "Crabserver:"
urls_crabserver="
/crabserver/preprod/info
/scheddmon/059/crabint1/
"
for u in $urls_crabserver; do
    perform_request "${base_url}${u}"
done
echo

# DAS
echo "DAS:"
urls_das="
/das
"
for u in $urls_das; do
    perform_request "${base_url}${u}"
done
echo

# DBS
echo "DBS:"
urls_dbs="
/dbs/int/global/DBSReader/serverinfo
/dbs/int/global/DBSReader/datasets?dataset=%2FWplusToJJZToLNuJJ_mjj100_pTj10_QCD_LO_TuneCP5_13TeV-madgraph-pythia8%2FRunIISummer20UL17MiniAODv2-106X_mc2017_realistic_v9-v2%2FMINIAODSIM&dataset_access_type=%2A&detail=False
/dbs/int/global/DBSReader/blocks?dataset=%2FWplusToJJZToLNuJJ_mjj100_pTj10_QCD_LO_TuneCP5_13TeV-madgraph-pythia8%2FRunIISummer20UL17MiniAODv2-106X_mc2017_realistic_v9-v2%2FMINIAODSIM&detail=False
/dbs/int/global/DBSReader/blocks?block_name=%2FWplusToJJZToLNuJJ_mjj100_pTj10_QCD_LO_TuneCP5_13TeV-madgraph-pythia8%2FRunIISummer20UL17MiniAODv2-106X_mc2017_realistic_v9-v2%2FMINIAODSIM%23f6557ea8-2493-4644-90a2-8a2fbb070abc
"
for u in $urls_dbs; do
    perform_request "${base_url}${u}"
done
echo

# DMWM
echo "DMWM:"
urls_dmwm="
/acdcserver/_all_docs
/reqmgr2/data/info 
/workqueue/index.html
/t0_reqmon/data/info 
/wmstatsserver/data/info
/wmstats/index.html
/exitcodes
/wmarchive/data 
/ms-transferor/data/status 
/ms-monitor/data/status 
/ms-output/data/status 
/ms-rulecleaner/data/status 
/ms-unmerged/data/status?rse_type=t1
/ms-unmerged/data/status?rse_type=t2t3
/ms-unmerged/data/status?rse_type=t2t3us
"
for u in $urls_dmwm; do
    perform_request "${base_url}${u}"
done
echo

# DQM
echo "DQM:"
urls_dqm="
/dqm/dqm-square/ 
/dqm/online/ 
/dqm/online-playback/ 
/dqm/offline/
/dqm/relval/
/dqm/dev/
/dqm/offline-test/
/dqm/relval-test/
"
for u in $urls_dqm; do
    perform_request "${base_url}${u}"
done
echo

# T0
echo "T0:"
urls_t0="
/t0wmadatasvc/prod/firstconditionsaferun
/t0wmadatasvc/prod/config
/t0wmadatasvc/prod/express_config
/t0wmadatasvc/prod/reco_config
"
for u in $urls_t0; do
    perform_request "${base_url}${u}"
done
echo

