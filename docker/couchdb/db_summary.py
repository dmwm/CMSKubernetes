#!/usr/bin/env python
"""
Script to list all databases in CouchDB and print a basic summary for each of them.
"""
import os
import sys
import socket
import requests
from itertools import chain

# Fetch a list of databases
resp = requests.get(f'http://localhost:5984/_all_dbs')
if resp.status_code >= 400:
    print(f"Failed to list databases: {resp.status_code}")
else:
    all_dbs = resp.json()
print(f"Node contains the following databases: {all_dbs}")
        
        
print(f"\n***** Summary of databases ****")
for db_name in all_dbs:
    resp = requests.get(f'http://localhost:5984/{db_name}')
    if resp.status_code >= 400:
        print(f"Request failed for db {db_name} with status code: {resp.status_code}")
    else:
        data = {}
        for kname, kdata in resp.json().items():
            if kname in ["db_name", "doc_count", "doc_del_count", "sizes"]:
                data[kname] = kdata
        print(data)
