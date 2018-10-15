#! /bin/bash

export KUBECONFIG=/afs/cern.ch/user/e/ewv/config

voms-proxy-init2 -valid 96:00 -cert /opt/rucio/certs/usercert.pem -key /opt/rucio/certs/new_userkey.pem -out /opt/rucio/certs/x509up -voms cms:/cms/Role=production -rfc -timeout 5

fts-rest-delegate  --key=/opt/rucio/certs/x509up --cert=/opt/rucio/certs/x509up -s https://fts3-devel.cern.ch:8446
fts-rest-delegate  --key=/opt/rucio/certs/x509up --cert=/opt/rucio/certs/x509up -s https://cmsfts3.fnal.gov:8446
fts-rest-delegate  --key=/opt/rucio/certs/x509up --cert=/opt/rucio/certs/x509up -s https://fts3.cern.ch:8446
fts-rest-delegate  --key=/opt/rucio/certs/x509up --cert=/opt/rucio/certs/x509up -s https://lcgfts3.gridpp.rl.ac.uk:8446
fts-rest-delegate  --key=/opt/rucio/certs/x509up --cert=/opt/rucio/certs/x509up -s https://fts3-pilot.cern.ch:8446

kubectl create secret generic  cms-ruciod-testbed-rucio-x509up --from-file=/opt/rucio/certs/x509up --dry-run -o yaml | kubectl apply --validate=false  -f  -

