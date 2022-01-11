#!/bin/bash

# Create ./test/log directory if not exist
[ -d ./log ] || mkdir -p ./log

BASE_PATH=/tmp/cmssqoop/rucio_dids/

sed -e "s,BASE_PATH=.*,BASE_PATH=${BASE_PATH},g" \
    -e "s,WHERE scope,WHERE ROWNUM <= 10 AND scope,g" \
    /data/sqoop/rucio_dids.sh >.test_rucio_dids.tmp
#bash .test_rucio_dids.tmp
#rm .test_rucio_dids.tmp
