#!/bin/bash
# this tar-ball should contain nats directory for NSC
if [ -f /etc/nats-nsc/nats-nsc.tar.gz ]; then
    tar xfz /etc/nats-nsc/nats-nsc.tar.gz
fi
if [ -d /data/nats/CMS ]; then
    if [ -f /etc/nats-nsc/nats-nsc.conf ]; then
        echo "nats-account-server -nsc /data/nats/CMS -c /data/nats-nsc.conf"
        nats-account-server -nsc /data/nats/CMS -c /etc/nats-nsc/nats-nsc.conf
    else
        echo "nats-account-server -nsc /data/nats/CMS -hp 0.0.0.0:9090"
        nats-account-server -nsc /data/nats/CMS -hp 0.0.0.0:9090
    fi
else
    echo "Unable to start nats-account-server, there is no credentials in /data/nats area"
    ls -alR /data
fi
