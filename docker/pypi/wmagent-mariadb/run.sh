#!/bin/bash

manage init-mariadb 2>&1 | tee -a run.log
manage start-mariadb 2>&1 | tee -a run.log

echo "Start sleeping....zzz"
while true; do sleep 10; done
