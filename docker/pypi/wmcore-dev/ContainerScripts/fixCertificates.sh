#! /bin/bash

set -x

# Certificates are either not readable by the container or have the wrong permissions

cp orig-certs/servicecert.pem.orig certs/servicecert.pem
cp orig-certs/servicekey.pem.orig certs/servicekey.pem
chmod 600 certs/servicecert.pem
chmod 400 certs/servicekey.pem
