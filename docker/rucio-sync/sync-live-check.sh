#! /bin/bash

out=`find /tmp/sync-alive.txt -mmin -10`
test -n "$out"