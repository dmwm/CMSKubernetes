#!/bin/bash

set -x
set -euo pipefail

# copy robotcert
sudo cp /etc/robots/robotkey.pem /data/srv/current/auth/crabserver/dmwm-service-key.pem
sudo cp /etc/robots/robotcert.pem /data/srv/current/auth/crabserver/dmwm-service-cert.pem
sudo chown $USER:$USER /data/srv/current/auth/crabserver/dmwm-service-key.pem
sudo chown $USER:$USER /data/srv/current/auth/crabserver/dmwm-service-cert.pem

# hmac key
sudo cp /etc/hmac/hmac /data/srv/current/auth/crabserver/header-auth-key
sudo chown $USER:$USER /data/srv/current/auth/crabserver/header-auth-key

# config.py
sudo cp /opt/config/config.py /data/srv/current/config/crabserver/config.py
sudo chown $USER:$USER /data/srv/current/config/crabserver/config.py

# CRABServerAuth.py
sudo cp /etc/secrets/CRABServerAuth.py /data/srv/current/auth/crabserver/CRABServerAuth.py
sudo chown $USER:$USER /data/srv/current/auth/crabserver/CRABServerAuth.py

# test X509_USER_PROXY
# Wa: I do not understand why we use this file instead of robotcert
ls /etc/proxy/proxy
export X509_USER_PROXY=/etc/proxy/proxy

# grid security
sudo cp /host/etc/grid-security/* /etc/grid-security
echo 'INFO Files in /etc/grid-security'
ls -lahZ /etc/grid-security

exec /usr/bin/tini -- /data/run.sh
