#!/bin/bash

# start process exporters
nohup process_monitor.sh ".*DBSGlobalReader" dbs_global_exporter ":18252" 15 2>&1 1>& dbs_global_exporter.log < /dev/null &
nohup process_monitor.sh ".*DBSGlobalWriter" dbs_globalW_exporter ":18253" 15 2>&1 1>& dbs_globalW_exporter.log < /dev/null &
nohup process_monitor.sh ".*DBSPhys03Reader" dbs_phys03R_exporter ":18254" 15 2>&1 1>& dbs_phys03R_exporter.log < /dev/null &
nohup process_monitor.sh ".*DBSPhys03Writer" dbs_phys03W_exporter ":18255" 15 2>&1 1>& dbs_phys03W_exporter.log < /dev/null &
nohup process_monitor.sh ".*DBSMigrate" dbs_migrate_exporter ":18251" 15 2>&1 1>& dbs_migrate_exporter.log < /dev/null &
nohup cpy_exporter -uri http://localhost:8254/dbs/stats -address ":19254" 2>&1 1>& cpy_exporter.log < /dev/null &
