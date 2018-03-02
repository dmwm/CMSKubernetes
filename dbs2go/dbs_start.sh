#!/bin/bash
# start dbs2go server
dbs_server -dbfile /tmp/dbs/dbfile.reader 2>&1 1>& dbs.log
