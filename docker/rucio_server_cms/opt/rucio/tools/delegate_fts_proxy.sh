#!/bin/bash

log="/var/log/rucio/delegate.log"
here=`dirname $0`
cd $here

date >> $log

voms-proxy-init \
	-voms cms \
	-cert /certs/usercert.pem \
	-key /certs/userkey.pem \
	-out /opt/rucio/etc/web/x509up \
	>> $log 2>&1

fts-delegation-init -v -s https://cmsfts3.fnal.gov:8446 --proxy /opt/rucio/etc/web/x509up
fts-delegation-init -v -s https://fts.mwt2.org:8446 --proxy /opt/rucio/etc/web/x509up
fts-delegation-init -v -s https://fts3.cern.ch:8446 --proxy /opt/rucio/etc/web/x509up
fts-delegation-init -v -s https://cmsftssrv2.fnal.gov:8446 --proxy /opt/rucio/etc/web/x509up
fts-delegation-init -v -s https://lcgfts3.gridpp.rl.ac.uk:8446 --proxy /opt/rucio/etc/web/x509up

echo >> $log
echo >> $log
