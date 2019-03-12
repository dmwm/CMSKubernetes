#!/bin/bash
# start https server
if [ -f /etc/secrets/httpsgoconfig.json ]; then
    echo "Config: /etc/secrets/httpsgoconfig.json"
    cat /etc/secrets/httpsgoconfig.json
    httpsgo -config /etc/secrets/httpsgoconfig.json
else
    echo "Config: config.json"
    cat config.json
    httpsgo -config config.json
fi
