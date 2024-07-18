#!/bin/bash

# Run fetch-crl to update CRLs
/usr/sbin/fetch-crl

# Copy updated CRLs to the appropriate directory
mkdir -p /host/etc/grid-security/certificates/
cp -rf /etc/grid-security/certificates/* /host/etc/grid-security/certificates/

