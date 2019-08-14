#!/usr/bin/env bash

# This script will create the various secrets needed by our installation. Before running set the following env variables

# HOSTP12 - The .p12 file from corresponding to the host certificate
# ROBOTCERT - The robot certificate (named usercert.pem)
# ROBOTKEY  - The robot certificate key (unencrypted, named new_userkey.pem)
# INSTANCE  - The instance name (dev/testbed/int/prod)

export DAEMON_NAME=cms-ruciod-${INSTANCE}
export SERVER_NAME=cms-rucio-${INSTANCE}

echo
echo "When prompted, enter the password used to encrypt the P12 file"

# Secret for redirecting server traffic from 443 to 80

# Setup files so that secretes are unavailable the least amount of time

openssl pkcs12 -in $HOSTP12 -clcerts -nokeys -out ./tls.crt
openssl pkcs12 -in $HOSTP12 -nocerts -nodes -out ./tls.key
# Secrets for the auth server
cp tls.key hostkey.pem
cp tls.crt hostcert.pem
cp /etc/pki/tls/certs/CERN_Root_CA.pem ca.pem
chmod 600 ca.pem


# Many of these are old names. Change as we slowly adopt the new names everywhere.

echo "Removing existing secrets"

kubectl delete secret rucio-server.tls-secret host-cert host-key ca 
kubectl delete secret ${DAEMON_NAME}-fts-cert ${DAEMON_NAME}-fts-key ${DAEMON_NAME}-hermes-cert ${DAEMON_NAME}-hermes-key 
kubectl delete secret cms-ruciod-testbed-rucio-ca-bundle webui-host-cert webui-host-key webui-cafile

echo "Creating new secrets"

kubectl create secret tls rucio-server.tls-secret --key=tls.key --cert=tls.crt

kubectl create secret generic ${SERVER_NAME}-hostcert --from-file=hostcert.pem
kubectl create secret generic ${SERVER_NAME}-hostkey --from-file=hostkey.pem
kubectl create secret generic ${SERVER_NAME}-cafile  --from-file=ca.pem

kubectl create secret generic ${DAEMON_NAME}-host-cert --from-file=hostcert.pem
kubectl create secret generic ${DAEMON_NAME}-host-key --from-file=hostkey.pem
kubectl create secret generic ${DAEMON_NAME}-cafile  --from-file=ca.pem

# Can these be parameterized in helm to be the same as above?
kubectl create secret generic webui-host-cert --from-file=hostcert.pem
kubectl create secret generic webui-host-key --from-file=hostkey.pem
cp /etc/pki/tls/certs/CERN-bundle.pem ca.pem
kubectl create secret generic webui-cafile --from-file=ca.pem

# Secrets for FTS, hermes

kubectl create secret generic ${DAEMON_NAME}-fts-cert --from-file=$ROBOTCERT
kubectl create secret generic ${DAEMON_NAME}-fts-key --from-file=$ROBOTKEY
kubectl create secret generic ${DAEMON_NAME}-hermes-cert --from-file=$ROBOTCERT
kubectl create secret generic ${DAEMON_NAME}-hermes-key --from-file=$ROBOTKEY
kubectl create secret generic ${DAEMON_NAME}-rucio-ca-bundle-reaper --from-file=/etc/pki/tls/certs/CERN-bundle.pem

# Secret for WebUI (should not be the robot cert, not needed now)

# cat $ROBOTCERT $ROBOTKEY > usercert_with_key.pem
# kubectl create secret generic webui-usercert --from-file=usercert_with_key.pem
# rm usercert_with_key.pem

# Clean up
rm tls.key tls.crt hostkey.pem hostcert.pem ca.pem

kubectl get secrets
