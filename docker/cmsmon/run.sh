#!/bin/bash
# start server
if [ -f /etc/secrets/cmsmon-config.json ]; then
    echo "Start with /etc/secrets/cmsmon-config.json"
    cat /etc/secrets/cmsmon-config.json
    cmsmon -config /etc/secrets/cmsmon-config.json
else
    echo "Start with $PWD/config.json"
    cat $PWD/config.json
    cmsmon -config $PWD/config.json
fi
