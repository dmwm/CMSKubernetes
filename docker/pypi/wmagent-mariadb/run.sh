#!/bin/bash

manage init-mariadb  2>&1 | tee -a $MDB_LOG_DIR/run.log
manage start-mariadb 2>&1 | tee -a $MDB_LOG_DIR/run.log

echo "Start sleeping....zzz"
while true; do sleep 10; done
