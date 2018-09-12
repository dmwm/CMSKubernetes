#!/bin/bash
# start server
echo "Start with $PWD/config.json"
cat $PWD/config.json
tfaas -config $PWD/config.json
