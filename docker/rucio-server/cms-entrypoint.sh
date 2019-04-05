#! /bin/bash

/usr/sbin/fetch-crl & 

/usr/sbin/crond 

/docker-entrypoint.sh
