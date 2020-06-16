#!/bin/bash
namespaces=`grep namespace storages/cephfs-storage-logs.yaml | awk '{print $2}'`
for ns in $namespaces; do
    echo "Create shares for namespaces: $ns"
    echo
    echo "manila create --share-type \"Meyrin CephFS\" --name ${ns}-share cephfs 100"
    #manila create --share-type "Meyrin CephFS" --name ${ns}-share cephfs 100
    echo
    echo "manila access-allow ${ns}-share cephx cmsweb-auth"
    manila access-allow ${ns}-share cephx cmsweb-auth
    echo
    echo "manila access-list ${ns}-share"
    manila access-list ${ns}-share
    echo
    echo "manila share-export-location-list ${ns}-share"
    manila share-export-location-list ${ns}-share
done
