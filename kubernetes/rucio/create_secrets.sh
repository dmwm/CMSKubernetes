#!/usr/bin/env bash

# This script will create the various secrets needed by our installation. Before running set the following env variables

# HOSTP12   - The .p12 file corresponding to the host certificate
# ROBOTP12  - The .p12 file corresponding to the robot certificate 
# INSTANCE  - The instance name (dev/testbed/int/prod)

export DAEMON_NAME=cms-ruciod-${INSTANCE}
export SERVER_NAME=cms-rucio-${INSTANCE}
export UI_NAME=cms-webui-${INSTANCE}


echo
echo "When prompted, enter the password used to encrypt the HOST P12 file"

# Setup files so that secrets are unavailable the least amount of time

openssl pkcs12 -in $HOSTP12 -clcerts -nokeys -out ./tls.crt
openssl pkcs12 -in $HOSTP12 -nocerts -nodes -out ./tls.key
# Secrets for the auth server
cp tls.key hostkey.pem
cp tls.crt hostcert.pem
cp /etc/pki/tls/certs/CERN_Root_CA.pem ca.pem
chmod 600 ca.pem


echo
echo "When prompted, enter the password used to encrypt the ROBOT P12 file"

openssl pkcs12 -in $ROBOTP12 -clcerts -nokeys -out usercert.pem
openssl pkcs12 -in $ROBOTP12 -nocerts -nodes -out new_userkey.pem

export ROBOTCERT=usercert.pem
export ROBOTKEY=new_userkey.pem

# Many of these are old names. Change as we slowly adopt the new names everywhere.

echo "Removing existing secrets"

kubectl delete secret rucio-server.tls-secret
kubectl delete secret ca host-key host-cert
kubectl delete secret ${DAEMON_NAME}-fts-cert ${DAEMON_NAME}-fts-key ${DAEMON_NAME}-hermes-cert ${DAEMON_NAME}-hermes-key 
kubectl delete secret ${DAEMON_NAME}-rucio-ca-bundle ${DAEMON_NAME}-rucio-ca-bundle-reaper
kubectl delete secret ${SERVER_NAME}-hostcert ${SERVER_NAME}-hostkey ${SERVER_NAME}-cafile  
kubectl delete secret ${DAEMON_NAME}-host-cert ${DAEMON_NAME}-host-key ${DAEMON_NAME}-cafile  
kubectl delete secret ${UI_NAME}-hostcert ${UI_NAME}-hostkey ${UI_NAME}-cafile webui-host-cert webui-host-key webui-cafile

echo "Creating new secrets"

kubectl create secret tls rucio-server.tls-secret --key=tls.key --cert=tls.crt

kubectl create secret generic ${SERVER_NAME}-hostcert --from-file=hostcert.pem
kubectl create secret generic ${SERVER_NAME}-hostkey --from-file=hostkey.pem
kubectl create secret generic ${SERVER_NAME}-cafile  --from-file=ca.pem

kubectl create secret generic ${SERVER_NAME}-auth-hostcert --from-file=hostcert.pem
kubectl create secret generic ${SERVER_NAME}-auth-hostkey --from-file=hostkey.pem
kubectl create secret generic ${SERVER_NAME}-auth-cafile  --from-file=ca.pem

kubectl create secret generic ${DAEMON_NAME}-host-cert --from-file=hostcert.pem
kubectl create secret generic ${DAEMON_NAME}-host-key --from-file=hostkey.pem
kubectl create secret generic ${DAEMON_NAME}-cafile  --from-file=ca.pem

# Make 1st set of stuff for WEBUI - maybe can remove later

export UI_NAME=webui
kubectl create secret generic ${UI_NAME}-host-cert --from-file=hostcert.pem
kubectl create secret generic ${UI_NAME}-host-key --from-file=hostkey.pem
kubectl create secret generic ${UI_NAME}-cafile  --from-file=ca.pem

# Make 2nd set of stuff for WEBUI - seems this is newer version
# We don't make the CA file here, but lower because it is different than the regular server

export UI_NAME=cms-webui-${INSTANCE}
kubectl create secret generic ${UI_NAME}-hostcert --from-file=hostcert.pem
kubectl create secret generic ${UI_NAME}-hostkey --from-file=hostkey.pem

# Secrets for FTS, hermes

kubectl create secret generic ${DAEMON_NAME}-fts-cert --from-file=$ROBOTCERT
kubectl create secret generic ${DAEMON_NAME}-fts-key --from-file=$ROBOTKEY
kubectl create secret generic ${DAEMON_NAME}-hermes-cert --from-file=$ROBOTCERT
kubectl create secret generic ${DAEMON_NAME}-hermes-key --from-file=$ROBOTKEY
kubectl create secret generic ${DAEMON_NAME}-rucio-ca-bundle --from-file=/etc/pki/tls/certs/CERN-bundle.pem
kubectl create secret generic ${DAEMON_NAME}-rucio-ca-bundle-reaper --from-file=/etc/pki/tls/certs/CERN-bundle.pem

# WebUI needs whole bundle as ca.pem. Keep this at end since we just over-wrote ca.pem

cp /etc/pki/tls/certs/CERN-bundle.pem ca.pem  
kubectl create secret generic ${UI_NAME}-cafile  --from-file=ca.pem

# Clean up
rm tls.key tls.crt hostkey.pem hostcert.pem ca.pem
rm usercert.pem new_userkey.pem

# Bundle may not be enough, build a whole directory of certificates
mkdir /tmp/reaper-certs
cp /etc/grid-security/certificates/*.0 /tmp/reaper-certs/
cp /etc/grid-security/certificates/*.signing_policy /tmp/reaper-certs/
kubectl delete secret ${DAEMON_NAME}-rucio-ca-bundle-reaper 
kubectl create secret generic ${DAEMON_NAME}-rucio-ca-bundle-reaper --from-file=/tmp/reaper-certs/
rm -rf /tmp/reaper-certs

kubectl get secrets
