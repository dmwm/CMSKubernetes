#!/bin/bash
url="https://cms-cric.cern.ch/api/accounts/user/query/?json&preset=roles"
curl -L -k \
    --key /etc/secrets/proxy --cert /etc/secrets/proxy \
    -q -o cric.json \
    -H "Accept: application/json" \
    "$url"
