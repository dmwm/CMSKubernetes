#! /bin/bash

export RUCIO_CFG_DATABASE_DEFAULT=`cat /afs/cern.ch/user/e/ewv/DBURL.txt`
export RUCIO_DEFINE_ALIASES=True
export RUCIO_ENABLE_SSL=True
export RUCIO_ENABLE_LOGFILE=True
export OPENSSL_ALLOW_PROXY_CERTS=1

cp etc/aliases.conf /tmp/aliases.conf   # Files on AFS cannot be read inside containers

docker run -d --privileged  \
  --name cms_rucio_auth \
  -e RUCIO_CFG_DATABASE_DEFAULT \
  -e RUCIO_DEFINE_ALIASES \
  -e RUCIO_ENABLE_SSL \
  -e RUCIO_ENABLE_LOGFILE \
  -e OPENSSL_ALLOW_PROXY_CERTS \
  -p 443:443 \
  -v /tmp/aliases.conf:/opt/rucio/etc/aliases.conf:z \
  -v /etc/grid-security/hostcert.pem:/etc/grid-security/hostcert.pem:z \
  -v /etc/grid-security/hostkey.pem:/etc/grid-security/hostkey.pem:z \
  -v /etc/pki/tls/certs/CERN_Root_CA.pem:/etc/grid-security/ca.pem:z \
 rucio/rucio-server



