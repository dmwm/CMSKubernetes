#!/bin/sh

cat /cephfs/product/dbs-logs/clients/curl-client-* | awk  '{sum+=$4} END {print "Avg time=",sum/NR}'

total=$(cat /cephfs/product/dbs-logs/clients/curl-client-* | awk  '{print $2}' | wc -l)

failure=$(cat /cephfs/product/dbs-logs/clients/curl-client-* | awk  '{print $2}' | grep -v 200 | wc -l)

echo "Total Requests: $total"
echo "Requests Failed: $failure"

echo $(bc -l <<<"${failure}/${total}")

