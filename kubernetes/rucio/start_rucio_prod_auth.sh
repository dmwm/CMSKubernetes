#! /bin/bash

# This can run in cron with the following line:
# 59 */6 * * * /opt/rucio/db/start_rucio_auth.sh

# Copy script into /opt/rucio/db (avoiding kerberos/AFS) and also testbed_db.txt. 
# Edit first line to get DB password from /opt/rucio/db
# Remove cp of aliases.conf and use '-v /opt/rucio/db/aliases.conf:/opt/rucio/etc/aliases.conf:z'  instead

export RUCIO_CFG_DATABASE_DEFAULT=`cat /afs/cern.ch/user/e/ewv/CMSKubernetes/kubernetes/rucio/prod_db.txt`
export RUCIO_DEFINE_ALIASES=True
export RUCIO_LOG_LEVEL=debug
export RUCIO_ENABLE_SSL=True
export RUCIO_ENABLE_LOGFILE=True
export OPENSSL_ALLOW_PROXY_CERTS=1
export RUCIO_CA_PATH=/etc/grid-security/certificates

cp etc/aliases.conf /tmp/aliases.conf   # Files on AFS cannot be read inside containers

docker kill cms_rucio_prod_auth
docker rm cms_rucio_prod_auth

docker run -d --privileged  \
  --name cms_rucio_prod_auth \
  -e RUCIO_CFG_DATABASE_DEFAULT \
  -e RUCIO_DEFINE_ALIASES \
  -e RUCIO_LOG_LEVEL \
  -e RUCIO_ENABLE_SSL \
  -e RUCIO_ENABLE_LOGFILE \
  -e RUCIO_CA_PATH \
  -e OPENSSL_ALLOW_PROXY_CERTS \
  -p 443:443 \
  -v /tmp/aliases.conf:/opt/rucio/etc/aliases.conf:z \
  -v /etc/grid-security/certificates:/etc/grid-security/certificates:z \
  -v /etc/grid-security/hostcert.pem:/etc/grid-security/hostcert.pem:z \
  -v /etc/grid-security/hostkey.pem:/etc/grid-security/hostkey.pem:z \
  -v /etc/pki/tls/certs/CERN_Root_CA.pem:/etc/grid-security/ca.pem:z \
rucio/rucio-server:latest

