#!/usr/bin/env bash

# This script will create the various secrets needed by our installation. Before running set the following env variables

# HOSTP12 - The .p12 file from corresponding to the host certificate
# ROBOTCERT - The robot certificate (named usercert.pem)
# ROBOTKEY  - The robot certificate key (unencrypted, named new_userkey.pem)

echo "Removing existing secrets"

kubectl delete secret rucio-server.tls-secret host-cert host-key ca fts-cert fts-key hermes-cert hermes-key cms-ruciod-testbed-rucio-ca-bundle

echo
echo "When prompted, enter the password used to encrypt the P12 file"

# Secret for redirecting server traffic from 443 to 80
openssl pkcs12 -in ~/.globus/Rucio/nginxtest4-4epk5oj55wka-minion-0.p12 -clcerts -nokeys -out ./tls.crt
openssl pkcs12 -in ~/.globus/Rucio/nginxtest4-4epk5oj55wka-minion-0.p12  -nocerts -nodes -out ./tls.key
kubectl create secret tls rucio-server.tls-secret --key=tls.key --cert=tls.crt

# Secrets for the auth server
cp tls.key hostkey.pem
cp tls.crt hostcert.pem
cp /etc/pki/tls/certs/CERN_Root_CA.pem ca.pem
chmod 600 ca.pem

kubectl create secret generic host-cert --from-file=hostcert.pem
kubectl create secret generic host-key --from-file=hostkey.pem
kubectl create secret generic ca  --from-file=ca.pem

# Clean up
rm tls.key tls.crt hostkey.pem hostcert.pem ca.pem

# Secrets for FTS, hermes

kubectl create secret generic fts-cert --from-file=$ROBOTCERT
kubectl create secret generic fts-key --from-file=$ROBOTKEY
kubectl create secret generic hermes-cert --from-file=$ROBOTCERT
kubectl create secret generic hermes-key --from-file=$ROBOTKEY
kubectl create secret generic cms-ruciod-testbed-rucio-ca-bundle --from-file=/etc/pki/tls/certs/CERN-bundle.pem


kubectl get secrets
