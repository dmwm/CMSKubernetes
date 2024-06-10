#!/usr/bin/env python
"""
Script meant to be used in the CouchDB VM migration, providing commands that need to
be executed in the backend VMs.
"""
import os
import sys
import socket
import requests
from itertools import chain

db_map = [{"src_node": "vocms0841", "target_node": "vocms0846", "db_names": ["workqueue", "workqueue_inbox"]},
          {"src_node": "vocms0842", "target_node": "vocms0847", "db_names": ["reqmgr_workload_cache", "reqmgr_config_cache",
                                                                             "acdcserver", "reqmgr_auxiliary"]}, 
          {"src_node": "vocms0843", "target_node": "vocms0848", "db_names": ["wmstats", "wmstats_logdb", "workloadsummary"]},
          {"src_node": "vocms0844", "target_node": "vocms0849", "db_names": ["tier0_wmstats", "t0_workloadsummary",
                                                                             "t0_request", "t0_logdb"]}]

if len(sys.argv) != 3:
    print(f"You need to provide a source and destination directory for the database shards.")
    print(f"Example: python3 check_couchdb.py /data/srv/couch_bkp_vocms0841/shards /data/srv/state/couchdb/database/shards")
    sys.exit(1)

src_dir = sys.argv[1]
dest_dir = sys.argv[2]
print(f"Meant to copy files from {src_dir} to {dest_dir}\n")

this_node = socket.gethostname()
all_dbs = []
for item in db_map:
    if item["target_node"] in this_node:
        these_db = item["db_names"]
    all_dbs.extend([db_name for db_name in item["db_names"]])
print(f"Running on node: {socket.gethostname()}, responsible for databases: {these_db}")

print(f"\n***** Summary of databases ****")
for db_name in all_dbs:
    resp = requests.get(f'http://localhost:5984/{db_name}')
    if resp.status_code >= 400:
        print(f"Request failed with status code: {resp.status_code}")
    else:
        data = {}
        for kname, kdata in resp.json().items():
            if kname in ["db_name", "doc_count", "doc_del_count", "sizes"]:
                data[kname] = kdata
        print(data)

print(f"\n***** Databases to be overwritten ****")
print(f"The following databases will need to be overwritten: {these_db}.\nPlease run these commands:")
for shard_dir in os.listdir(dest_dir):
    src_dir_shard = os.path.join(src_dir, shard_dir)
    src_dir_content = os.listdir(src_dir_shard)
    #print(f"Content of source directory {src_dir_shard}: {src_dir_content}")
    dest_dir_shard = os.path.join(dest_dir, shard_dir)
    dest_dir_content = os.listdir(dest_dir_shard)
    #print(f"Content of destination directory {dest_dir_shard}: {dest_dir_content}")
    for db_name in these_db:
        for src_db in src_dir_content:
            if db_name == src_db.split(".")[0]:
                break
        for dest_db in dest_dir_content:
            if db_name == dest_db.split(".")[0]:
                break
        print(f"cp {os.path.join(src_dir_shard, src_db)} {os.path.join(dest_dir_shard, dest_db)}")
