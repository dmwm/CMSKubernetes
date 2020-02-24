#!/bin/bash
url="https://cms-cric.cern.ch/api/accounts/user/query/?json&preset=roles"
curl -V
curl -v -L -k \
    -q -o /tmp/cric.json \
    -H "Accept: application/json" \
    "$url"
# move cric data to cric storage
if [ -d /cric ]; then
    mv /tmp/cric.json /cric
fi
