#!/bin/bash

# start process exporters
if [ -f /etc/secrets/DBSMigrate.py ]; then
    process_monitor.sh ".*DBSMigrate" dbs_migrate_exporter ":18257" 15 2>&1 1>& dbs_migrate_exporter.log &
    cpy_exporter -uri http://localhost:8257/dbs/stats -address ":19257" 2>&1 1>& cpy_exporter.log &
fi
if [ -f /etc/secrets/DBSGlobalReader.py ]; then
    process_monitor.sh ".*DBSGlobalReader" dbs_global_exporter ":18252" 15 2>&1 1>& dbs_global_exporter.log &
    cpy_exporter -uri http://localhost:8252/dbs/stats -address ":19252" 2>&1 1>& cpy_exporter.log &
fi
if [ -f /etc/secrets/DBSGlobalWriter.py ]; then
    process_monitor.sh ".*DBSGlobalWriter" dbs_globalW_exporter ":18253" 15 2>&1 1>& dbs_globalW_exporter.log &
    cpy_exporter -uri http://localhost:8253/dbs/stats -address ":19253" 2>&1 1>& cpy_exporter.log &
fi
if [ -f /etc/secrets/DBSPhys03Reader.py ]; then
    process_monitor.sh ".*DBSPhys03Reader" dbs_phys03R_exporter ":18254" 15 2>&1 1>& dbs_phys03R_exporter.log &
    cpy_exporter -uri http://localhost:8254/dbs/stats -address ":19254" 2>&1 1>& cpy_exporter.log &
fi
if [ -f /etc/secrets/DBSPhys03Writer.py ]; then
    process_monitor.sh ".*DBSPhys03Writer" dbs_phys03W_exporter ":18255" 15 2>&1 1>& dbs_phys03W_exporter.log &
    cpy_exporter -uri http://localhost:8255/dbs/stats -address ":19255" 2>&1 1>& cpy_exporter.log &
fi

# run filebeat
if [ -f /etc/secrets/filebeat.yaml ] && [ -f /usr/bin/filebeat ]; then
    ldir=/tmp/filebeat
    mkdir -p $ldir/data
    nohup /usr/bin/filebeat \
        -c /etc/secrets/filebeat.yaml \
        --path.data $ldir/data --path.logs $ldir -e 2>&1 1>& $ldir/log < /dev/null &
fi
