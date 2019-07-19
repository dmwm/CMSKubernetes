#!/bin/bash

# overwrite proxy if it is present in /etc/proxy
if [ -f /etc/proxy/proxy ]; then
    mkdir -p /data/srv/state/reqmgr2/proxy
    ln -s /etc/proxy/proxy /data/srv/state/reqmgr2/proxy/proxy.cert
    mkdir -p /data/srv/current/auth/proxy
    ln -s /etc/proxy/proxy /data/srv/current/auth/proxy/proxy
fi

# overwrite header-auth key file with one from secrets
if [ -f /etc/secrets/hmac ]; then
    sudo rm /data/srv/current/auth/wmcore-auth/header-auth-key
    cp /etc/secrets/hmac /data/srv/current/auth/wmcore-auth/header-auth-key
    # generate new hmac key for couch
    chmod u+w /data/srv/current/auth/couchdb/hmackey.ini
    perl -e 'undef $/; print "[couch_cms_auth]\n"; print "hmac_secret = ", unpack("h*", <STDIN>), "\n"' < /etc/secrets/hmac > /data/srv/current/auth/couchdb/hmackey.ini
    chmod ug+rx,o-rwx /data/srv/current/auth/couchdb/hmackey.ini
fi

# start the service
/data/srv/current/config/couchdb/manage start 'I did read documentation'

# setup all necessary DBs for our services
source /data/srv/current/apps/couchdb/etc/profile.d/init.sh
couchdb_url=http://localhost:5984

# acdcserver
couchapp push /data/srv/current/apps/acdcserver/data/couchapps/ACDC ${couchdb_url}/acdcserver
couchapp push /data/srv/current/apps/acdcserver/data/couchapps/GroupUser ${couchdb_url}/acdcserver

# alertscollector
couchapp push  /data/srv/current/apps/alertscollector/data/couchapps/AlertsCollector ${couchdb_url}/alertscollector

# reqmgr2
couchapp push /data/srv/current/apps/reqmgr2/data/couchapps/ReqMgrAux ${couchdb_url}/reqmgr_auxiliary
couchapp push /data/srv/current/apps/reqmgr2/data/couchapps/WMDataMining ${couchdb_url}/wmdatamining
couchapp push /data/srv/current/apps/reqmgr2/data/couchapps/ReqMgr ${couchdb_url}/reqmgr_workload_cache
couchapp push /data/srv/current/apps/reqmgr2/data/couchapps/ConfigCache ${couchdb_url}/reqmgr_config_cache

# reqmon
couchapp push /data/srv/current/apps/reqmon/data/couchapps/WMStats ${couchdb_url}/wmstats
couchapp push /data/srv/current/apps/reqmon/data/couchapps/WMStatsErl ${couchdb_url}/wmstats
couchapp push /data/srv/current/apps/reqmon/data/couchapps/WorkloadSummary ${couchdb_url}/workloadsummary
couchapp push /data/srv/current/apps/reqmon/data/couchapps/LogDB ${couchdb_url}/wmstats_logdb

# t0_reqmon
couchapp push /data/srv/current/apps/t0_reqmon/data/couchapps/WMStats ${couchdb_url}/tier0_wmstats
couchapp push /data/srv/current/apps/t0_reqmon/data/couchapps/WMStatsErl ${couchdb_url}/tier0_wmstats
couchapp push /data/srv/current/apps/t0_reqmon/data/couchapps/T0Request ${couchdb_url}/t0_request
couchapp push /data/srv/current/apps/t0_reqmon/data/couchapps/WorkloadSummary ${couchdb_url}/t0_workloadsummary
couchapp push /data/srv/current/apps/t0_reqmon/data/couchapps/LogDB ${couchdb_url}/t0_logdb

# workqueue
/data/srv/current/config/workqueue/manage pushcouchapp ${couchdb_url}

# start cron daemon
sudo /usr/sbin/crond -n
