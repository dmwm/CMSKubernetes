#!/bin/bash

# Run fetch-crl to update CRLs
/usr/sbin/fetch-crl

# Copy updated CRLs to the appropriate directory
cp /etc/grid-security/*.pem /host/etc/grid-security/

